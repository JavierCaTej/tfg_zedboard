#define _POSIX_C_SOURCE 200809L

/*
 * tfg_axi_memtool
 *
 * Este programa es la herramienta que uso en Linux para comprobar que mi
 * periferico AXI-Lite responde y para medir accesos desde espacio de usuario.
 * En vez de hacer un driver de kernel, que seria mas complejo para esta fase,
 * uso /dev/mem para mapear la direccion fisica del IP y acceder a sus
 * registros directamente.
 *
 * De cara al TFG, esta utilidad me sirve para justificar dos cosas:
 * 1. Que el hardware integrado en la PL esta accesible desde Linux.
 * 2. Que puedo repetir lecturas/escrituras y guardar tiempos en CSV.
 *
 * La base por defecto es 0x40000000 porque es la direccion que deje asignada
 * en Vivado y tambien la que se describe en el device tree.
 */

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include "tfg_axi_lite_regs.h"

#define DEFAULT_BASE_ADDR 0x40000000ull
#define DEFAULT_MAP_SIZE  0x1000u
#define DEFAULT_ITERS     1000u
#define DEFAULT_WARMUP    0u
#define DEFAULT_DEV_MEM   "/dev/mem"
#define DEFAULT_BUILD_ID  "manual"
#define DEFAULT_CSV_DIR   "."
#define TEST_VALUE        0xA5A55A5Au

#define EXIT_USAGE        1
#define EXIT_OPEN_ERROR   2
#define EXIT_MMAP_ERROR   3
#define EXIT_ID_ERROR     4
#define EXIT_VERIFY_ERROR 5

/*
 * Guardo la configuracion en variables globales para que el codigo sea facil
 * de leer. El programa solo trabaja con un periferico, asi que no necesito una
 * estructura compleja para pasar estos datos por todas las funciones.
 */
static uint64_t g_base_addr = DEFAULT_BASE_ADDR;
static uint32_t g_map_size = DEFAULT_MAP_SIZE;
static uint32_t g_iters = DEFAULT_ITERS;
static uint32_t g_warmup = DEFAULT_WARMUP;
static const char *g_dev_mem = DEFAULT_DEV_MEM;
static const char *g_build_id = DEFAULT_BUILD_ID;
static const char *g_csv_dir = DEFAULT_CSV_DIR;
static bool g_csv = false;
static bool g_check_id = true;

static int g_fd = -1;
static void *g_map = NULL;
static size_t g_map_len = 0;

/*
 * Este puntero apunta al inicio de los registros del IP.
 *
 * Uso volatile porque no estoy leyendo RAM normal, sino registros hardware.
 * Si el compilador optimiza demasiado, podria quitar o juntar accesos que para
 * mi prueba si tienen que llegar realmente al bus AXI.
 */
static volatile uint8_t *g_regs = NULL;

/*
 * Muestra los comandos disponibles. Esto me permite ejecutar el binario desde
 * la placa sin tener que mirar el codigo cada vez que quiero recordar opciones.
 */
static void usage(const char *prog)
{
    fprintf(stderr,
            "Uso: %s [opciones] <comando> [argumentos]\n"
            "\n"
            "Comandos:\n"
            "  smoke                         Prueba REG_ID, REG_VERSION y eco WDATA/RDATA\n"
            "  read <offset>                 Lee un registro de 32 bits\n"
            "  write <offset> <value>        Escribe un registro de 32 bits\n"
            "  read-loop <offset>            Mide lecturas repetidas\n"
            "  write-loop <offset> <value>   Mide escrituras repetidas\n"
            "  rw-loop [value]               Mide write WDATA + read RDATA y verifica eco\n"
            "\n"
            "Opciones:\n"
            "  --base <addr>       Direccion fisica base (defecto: 0x40000000)\n"
            "  --size <bytes>      Tamano de ventana (defecto: 0x1000)\n"
            "  --dev <path>        Dispositivo de memoria (defecto: /dev/mem)\n"
            "  --iters <n>         Iteraciones medidas (defecto: 1000)\n"
            "  --warmup <n>        Iteraciones de calentamiento (defecto: 0)\n"
            "  --build-id <text>   Identificador de la prueba\n"
            "  -C <dir>            Carpeta donde guardar el CSV de rw-loop\n"
            "  --csv-dir <dir>     Igual que -C\n"
            "  --csv               Imprime el resultado en CSV\n"
            "  --no-id-check       No comprueba REG_ID antes de operar\n"
            "  -h, --help          Muestra esta ayuda\n",
            prog);
}

/*
 * Convierte texto a numero. Uso base 0 para poder escribir tanto decimal como
 * hexadecimal, por ejemplo 4096 o 0x1000.
 */
static bool parse_u64(const char *text, uint64_t *out)
{
    char *end = NULL;
    uint64_t value;

    errno = 0;
    value = strtoull(text, &end, 0);
    if (errno != 0 || end == text || *end != '\0') {
        return false;
    }

    *out = value;
    return true;
}

/*
 * Igual que la anterior, pero limitando el resultado a 32 bits. Lo uso para
 * offsets de registros, valores escritos e iteraciones.
 */
static bool parse_u32(const char *text, uint32_t *out)
{
    uint64_t value = 0;

    if (!parse_u64(text, &value)) {
        return false;
    }
    if (value > UINT32_MAX) {
        return false;
    }

    *out = (uint32_t)value;
    return true;
}

/*
 * Devuelve un tiempo en nanosegundos. No busco la hora real, sino medir cuanto
 * tarda un bucle de accesos. Luego divido este tiempo entre iteraciones.
 */
static uint64_t get_time_ns(void)
{
    struct timespec ts;

#ifdef CLOCK_MONOTONIC_RAW
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
#else
    clock_gettime(CLOCK_MONOTONIC, &ts);
#endif

    return ((uint64_t)ts.tv_sec * 1000000000ull) + (uint64_t)ts.tv_nsec;
}

/*
 * Comprueba que el offset tiene sentido para mi mapa de registros. Como los
 * registros son de 32 bits, no permito offsets desalineados.
 */
static bool offset_ok(uint32_t offset)
{
    if ((offset % 4u) != 0u) {
        return false;
    }
    if (offset > (g_map_size - 4u)) {
        return false;
    }
    return true;
}

/*
 * Lee un registro de 32 bits. El offset es relativo a la base del IP, no una
 * direccion fisica completa.
 */
static uint32_t read32(uint32_t offset)
{
    volatile uint32_t *reg = (volatile uint32_t *)(g_regs + offset);
    return *reg;
}

/*
 * Escribe un registro de 32 bits. Esta funcion es la pareja de read32 y deja
 * el acceso al hardware concentrado en un sitio.
 */
static void write32(uint32_t offset, uint32_t value)
{
    volatile uint32_t *reg = (volatile uint32_t *)(g_regs + offset);
    *reg = value;
}

/*
 * Abre /dev/mem y crea el mapeo con mmap. Esta es la parte que conecta el
 * programa de usuario con la direccion fisica del periferico.
 */
static int map_hw(void)
{
    long page_size;
    uint64_t page_mask;
    uint64_t page_base;
    uint64_t page_offset;

    page_size = sysconf(_SC_PAGESIZE);
    if (page_size <= 0) {
        page_size = 4096;
    }

    /*
     * mmap trabaja por paginas. Por eso no mapeo directamente 0x40000000 sin
     * pensar: primero calculo la pagina donde cae la direccion y despues el
     * desplazamiento hasta el inicio real del IP.
     */
    page_mask = (uint64_t)page_size - 1u;
    page_base = g_base_addr & ~page_mask;
    page_offset = g_base_addr - page_base;
    g_map_len = (size_t)page_offset + g_map_size;
    g_map_len = (g_map_len + (size_t)page_mask) & ~(size_t)page_mask;

    g_fd = open(g_dev_mem, O_RDWR | O_SYNC);
    if (g_fd < 0) {
        perror("open /dev/mem");
        return EXIT_OPEN_ERROR;
    }

    g_map = mmap(NULL, g_map_len, PROT_READ | PROT_WRITE, MAP_SHARED, g_fd, (off_t)page_base);
    if (g_map == MAP_FAILED) {
        perror("mmap");
        close(g_fd);
        g_fd = -1;
        return EXIT_MMAP_ERROR;
    }

    g_regs = (volatile uint8_t *)g_map + page_offset;
    return 0;
}

/*
 * Libera los recursos usados para acceder a /dev/mem. Lo llamo al final para
 * no dejar el descriptor ni el mmap abiertos.
 */
static void unmap_hw(void)
{
    if (g_map != NULL && g_map != MAP_FAILED) {
        munmap(g_map, g_map_len);
    }
    if (g_fd >= 0) {
        close(g_fd);
    }
}

/*
 * Antes de medir compruebo REG_ID. Si este valor no coincide, prefiero parar,
 * porque significaria que la PL no esta cargada, la base esta mal o no estoy
 * accediendo al periferico que toca.
 */
static int check_reg_id(void)
{
    uint32_t id = read32(TFG_AXI_LITE_REGS_REG_ID);

    if (id != TFG_AXI_LITE_REGS_ID_VALUE) {
        fprintf(stderr, "REG_ID inesperado: leido=0x%08" PRIx32 " esperado=0x%08x\n",
                id, TFG_AXI_LITE_REGS_ID_VALUE);
        return EXIT_ID_ERROR;
    }

    return 0;
}

/*
 * Imprime el resultado de una medida. El dato mas importante es avg_ns, que es
 * el tiempo medio por iteracion. No es la ultima iteracion: es la media de todo
 * el bucle medido.
 */
static void print_result(const char *op, uint32_t offset, uint64_t elapsed_ns, uint32_t mismatches)
{
    double avg_ns = 0.0;

    if (g_iters > 0) {
        avg_ns = (double)elapsed_ns / (double)g_iters;
    }

    if (g_csv) {
        time_t timestamp = time(NULL);

        puts("timestamp,build_id,base_addr,op,offset,iters,warmup,elapsed_ns,avg_ns,mismatches");
        printf("%ld,%s,0x%08" PRIx64 ",%s,0x%08" PRIx32 ",%" PRIu32 ",%" PRIu32
               ",%" PRIu64 ",%.3f,%" PRIu32 "\n",
               (long)timestamp,
               g_build_id,
               g_base_addr,
               op,
               offset,
               g_iters,
               g_warmup,
               elapsed_ns,
               avg_ns,
               mismatches);
    } else {
        printf("build_id=%s\n", g_build_id);
        printf("base_addr=0x%08" PRIx64 "\n", g_base_addr);
        printf("op=%s\n", op);
        printf("offset=0x%08" PRIx32 "\n", offset);
        printf("iters=%" PRIu32 "\n", g_iters);
        printf("warmup=%" PRIu32 "\n", g_warmup);
        printf("elapsed_ns=%" PRIu64 "\n", elapsed_ns);
        printf("avg_ns=%.3f\n", avg_ns);
        printf("mismatches=%" PRIu32 "\n", mismatches);
    }
}

/*
 * Guarda el resultado de rw-loop en un fichero CSV.
 *
 * Lo hago aqui para no depender de copiar la salida de UART. Cada ejecucion
 * crea un nombre distinto usando fecha, hora y pid del proceso. Si no uso -C,
 * el fichero se queda en el directorio desde donde lance el comando.
 */
static int save_rw_csv(uint32_t offset, uint64_t elapsed_ns, uint32_t mismatches)
{
    char timestamp_name[32];
    char csv_path[512];
    struct tm tm_info;
    time_t now;
    FILE *csv_file;
    double avg_ns = 0.0;

    if (g_iters > 0) {
        avg_ns = (double)elapsed_ns / (double)g_iters;
    }

    /*
     * Intento crear la carpeta indicada. Si ya existe no es un error.
     * Para rutas con varios niveles, por ejemplo /root/t10/resultados, esos
     * niveles tienen que existir previamente.
     */
    if (mkdir(g_csv_dir, 0777) != 0 && errno != EEXIST) {
        perror("mkdir csv dir");
        return EXIT_OPEN_ERROR;
    }

    now = time(NULL);
    if (localtime_r(&now, &tm_info) == NULL) {
        snprintf(timestamp_name, sizeof(timestamp_name), "sin_fecha");
    } else {
        strftime(timestamp_name, sizeof(timestamp_name), "%Y%m%d_%H%M%S", &tm_info);
    }

    snprintf(csv_path, sizeof(csv_path), "%s/tfg_axi_memtool_rw_loop_%s_%ld.csv",
             g_csv_dir, timestamp_name, (long)getpid());

    csv_file = fopen(csv_path, "w");
    if (csv_file == NULL) {
        perror("fopen csv");
        return EXIT_OPEN_ERROR;
    }

    fprintf(csv_file,
            "timestamp,build_id,base_addr,op,offset,iters,warmup,elapsed_ns,avg_ns,mismatches\n");
    fprintf(csv_file,
            "%ld,%s,0x%08" PRIx64 ",rw_loop,0x%08" PRIx32 ",%" PRIu32 ",%" PRIu32
            ",%" PRIu64 ",%.3f,%" PRIu32 "\n",
            (long)now,
            g_build_id,
            g_base_addr,
            offset,
            g_iters,
            g_warmup,
            elapsed_ns,
            avg_ns,
            mismatches);

    fclose(csv_file);

    /*
     * Lo saco por stderr para no romper la salida CSV por stdout cuando uso
     * --csv. Asi puedo ver igualmente donde se ha guardado el fichero.
     */
    fprintf(stderr, "csv_file=%s\n", csv_path);
    return 0;
}

/*
 * Prueba rapida de funcionamiento.
 *
 * Esta es la primera prueba que ejecutaria delante del jurado: leo el ID y la
 * version, escribo un valor conocido en WDATA y compruebo que RDATA devuelve
 * lo mismo. Si esto pasa, puedo decir que el camino PS -> AXI -> IP -> AXI ->
 * PS funciona para una operacion basica.
 */
static int cmd_smoke(void)
{
    uint32_t id;
    uint32_t version;
    uint32_t status;
    uint32_t rdata;
    uint32_t write_count;
    uint32_t read_count;

    id = read32(TFG_AXI_LITE_REGS_REG_ID);
    version = read32(TFG_AXI_LITE_REGS_REG_VERSION);
    status = read32(TFG_AXI_LITE_REGS_REG_STATUS);

    if (id != TFG_AXI_LITE_REGS_ID_VALUE) {
        fprintf(stderr, "FAIL: REG_ID=0x%08" PRIx32 " esperado=0x%08x\n",
                id, TFG_AXI_LITE_REGS_ID_VALUE);
        return EXIT_ID_ERROR;
    }

    write32(TFG_AXI_LITE_REGS_REG_CONTROL, TFG_AXI_LITE_REGS_CONTROL_CLEAR_COUNTERS_MASK);
    write32(TFG_AXI_LITE_REGS_REG_WDATA, TEST_VALUE);

    rdata = read32(TFG_AXI_LITE_REGS_REG_RDATA);
    write_count = read32(TFG_AXI_LITE_REGS_REG_WRITE_COUNT);
    read_count = read32(TFG_AXI_LITE_REGS_REG_READ_COUNT);

    printf("id=0x%08" PRIx32 "\n", id);
    printf("version=0x%08" PRIx32 "\n", version);
    printf("status=0x%08" PRIx32 "\n", status);
    printf("wdata=0x%08x\n", TEST_VALUE);
    printf("rdata=0x%08" PRIx32 "\n", rdata);
    printf("write_count=%" PRIu32 "\n", write_count);
    printf("read_count=%" PRIu32 "\n", read_count);

    if (rdata != TEST_VALUE) {
        fprintf(stderr, "FAIL: RDATA no coincide con WDATA\n");
        return EXIT_VERIFY_ERROR;
    }

    puts("result=PASS");
    return 0;
}

/*
 * Lee un registro concreto. Me sirve para comprobar valores puntuales, por
 * ejemplo que el offset 0x00 devuelve el identificador del IP.
 */
static int cmd_read(const char *offset_text)
{
    uint32_t offset = 0;

    if (!parse_u32(offset_text, &offset) || !offset_ok(offset)) {
        fprintf(stderr, "Offset invalido: %s\n", offset_text);
        return EXIT_USAGE;
    }

    printf("0x%08" PRIx32 "\n", read32(offset));
    return 0;
}

/*
 * Escribe un registro concreto. Lo dejo como herramienta de depuracion manual,
 * por ejemplo para escribir WDATA o algun registro de control.
 */
static int cmd_write(const char *offset_text, const char *value_text)
{
    uint32_t offset = 0;
    uint32_t value = 0;

    if (!parse_u32(offset_text, &offset) || !offset_ok(offset)) {
        fprintf(stderr, "Offset invalido: %s\n", offset_text);
        return EXIT_USAGE;
    }
    if (!parse_u32(value_text, &value)) {
        fprintf(stderr, "Valor invalido: %s\n", value_text);
        return EXIT_USAGE;
    }

    write32(offset, value);
    printf("write offset=0x%08" PRIx32 " value=0x%08" PRIx32 "\n", offset, value);
    return 0;
}

/*
 * Mide muchas lecturas seguidas sobre el mismo registro.
 *
 * Primero hago un warmup que no se mide. Despues tomo el tiempo del bucle real
 * y calculo la media. dummy existe para usar el dato leido y evitar que el
 * compilador piense que la lectura no sirve para nada.
 */
static int cmd_read_loop(const char *offset_text)
{
    uint32_t offset = 0;
    uint32_t i;
    uint64_t start;
    uint64_t elapsed;
    volatile uint32_t dummy = 0;

    if (!parse_u32(offset_text, &offset) || !offset_ok(offset)) {
        fprintf(stderr, "Offset invalido: %s\n", offset_text);
        return EXIT_USAGE;
    }

    for (i = 0; i < g_warmup; i++) {
        dummy ^= read32(offset);
    }

    start = get_time_ns();
    for (i = 0; i < g_iters; i++) {
        dummy ^= read32(offset);
    }
    elapsed = get_time_ns() - start;

    (void)dummy;
    print_result("read_loop", offset, elapsed, 0);
    return 0;
}

/*
 * Mide muchas escrituras seguidas. En cada iteracion escribo value+i para que
 * no sea exactamente siempre el mismo dato.
 */
static int cmd_write_loop(const char *offset_text, const char *value_text)
{
    uint32_t offset = 0;
    uint32_t value = 0;
    uint32_t i;
    uint64_t start;
    uint64_t elapsed;

    if (!parse_u32(offset_text, &offset) || !offset_ok(offset)) {
        fprintf(stderr, "Offset invalido: %s\n", offset_text);
        return EXIT_USAGE;
    }
    if (!parse_u32(value_text, &value)) {
        fprintf(stderr, "Valor invalido: %s\n", value_text);
        return EXIT_USAGE;
    }

    for (i = 0; i < g_warmup; i++) {
        write32(offset, value + i);
    }

    start = get_time_ns();
    for (i = 0; i < g_iters; i++) {
        write32(offset, value + i);
    }
    elapsed = get_time_ns() - start;

    print_result("write_loop", offset, elapsed, 0);
    return 0;
}

/*
 * Mide escritura + lectura. Este es el modo que mas uso para el TFG porque
 * comprueba funcionalidad y tiempo a la vez: escribo en WDATA, leo RDATA y
 * cuento errores si no coincide.
 */
static int cmd_rw_loop(const char *value_text)
{
    uint32_t value = TEST_VALUE;
    uint32_t mismatches = 0;
    uint32_t i;
    uint64_t start;
    uint64_t elapsed;

    if (value_text != NULL && !parse_u32(value_text, &value)) {
        fprintf(stderr, "Valor invalido: %s\n", value_text);
        return EXIT_USAGE;
    }

    for (i = 0; i < g_warmup; i++) {
        uint32_t expected = value + i;

        write32(TFG_AXI_LITE_REGS_REG_WDATA, expected);
        (void)read32(TFG_AXI_LITE_REGS_REG_RDATA);
    }

    start = get_time_ns();
    for (i = 0; i < g_iters; i++) {
        uint32_t expected = value + i;
        uint32_t observed;

        write32(TFG_AXI_LITE_REGS_REG_WDATA, expected);
        observed = read32(TFG_AXI_LITE_REGS_REG_RDATA);

        if (observed != expected) {
            mismatches++;
        }
    }
    elapsed = get_time_ns() - start;

    print_result("rw_loop", TFG_AXI_LITE_REGS_REG_WDATA, elapsed, mismatches);

    if (save_rw_csv(TFG_AXI_LITE_REGS_REG_WDATA, elapsed, mismatches) != 0) {
        return EXIT_OPEN_ERROR;
    }

    if (mismatches != 0) {
        return EXIT_VERIFY_ERROR;
    }
    return 0;
}

int main(int argc, char **argv)
{
    const char *cmd = NULL;
    const char *args[4] = {0};
    int arg_count = 0;
    int rc;
    int i;

    /*
     * Parser simple. Recorro argv a mano porque la herramienta tiene pocas
     * opciones y asi el codigo queda facil de seguir para mi memoria del TFG.
     */
    for (i = 1; i < argc; i++) {
        const char *arg = argv[i];

        if (strcmp(arg, "-h") == 0 || strcmp(arg, "--help") == 0) {
            usage(argv[0]);
            return 0;
        } else if (strcmp(arg, "--csv") == 0) {
            g_csv = true;
        } else if (strcmp(arg, "--no-id-check") == 0) {
            g_check_id = false;
        } else if (strcmp(arg, "--base") == 0 && i + 1 < argc) {
            i++;
            if (!parse_u64(argv[i], &g_base_addr)) {
                fprintf(stderr, "Direccion base invalida\n");
                return EXIT_USAGE;
            }
        } else if (strcmp(arg, "--size") == 0 && i + 1 < argc) {
            i++;
            if (!parse_u32(argv[i], &g_map_size) || g_map_size < 4u) {
                fprintf(stderr, "Tamano de ventana invalido\n");
                return EXIT_USAGE;
            }
        } else if (strcmp(arg, "--dev") == 0 && i + 1 < argc) {
            i++;
            g_dev_mem = argv[i];
        } else if (strcmp(arg, "--iters") == 0 && i + 1 < argc) {
            i++;
            if (!parse_u32(argv[i], &g_iters)) {
                fprintf(stderr, "Iteraciones invalidas\n");
                return EXIT_USAGE;
            }
        } else if (strcmp(arg, "--warmup") == 0 && i + 1 < argc) {
            i++;
            if (!parse_u32(argv[i], &g_warmup)) {
                fprintf(stderr, "Warmup invalido\n");
                return EXIT_USAGE;
            }
        } else if (strcmp(arg, "--build-id") == 0 && i + 1 < argc) {
            i++;
            g_build_id = argv[i];
        } else if ((strcmp(arg, "-C") == 0 || strcmp(arg, "--csv-dir") == 0) && i + 1 < argc) {
            i++;
            g_csv_dir = argv[i];
        } else if (arg[0] == '-' && cmd == NULL) {
            fprintf(stderr, "Opcion desconocida: %s\n", arg);
            return EXIT_USAGE;
        } else if (cmd == NULL) {
            cmd = arg;
        } else if (arg_count < 4) {
            args[arg_count] = arg;
            arg_count++;
        } else {
            fprintf(stderr, "Demasiados argumentos\n");
            return EXIT_USAGE;
        }
    }

    if (cmd == NULL) {
        usage(argv[0]);
        return EXIT_USAGE;
    }

    /* Primero mapeo el hardware. Sin este paso no puedo acceder a registros. */
    rc = map_hw();
    if (rc != 0) {
        return rc;
    }

    /*
     * Despues compruebo que el periferico responde con el ID esperado. Esta
     * comprobacion evita medir una direccion equivocada.
     */
    if (g_check_id) {
        rc = check_reg_id();
        if (rc != 0) {
            unmap_hw();
            return rc;
        }
    }

    /*
     * Aqui ejecuto el comando elegido. Todos los comandos usan el mismo mapeo
     * de memoria, pero cada uno hace una prueba distinta.
     */
    if (strcmp(cmd, "smoke") == 0 && arg_count == 0) {
        rc = cmd_smoke();
    } else if (strcmp(cmd, "read") == 0 && arg_count == 1) {
        rc = cmd_read(args[0]);
    } else if (strcmp(cmd, "write") == 0 && arg_count == 2) {
        rc = cmd_write(args[0], args[1]);
    } else if (strcmp(cmd, "read-loop") == 0 && arg_count == 1) {
        rc = cmd_read_loop(args[0]);
    } else if (strcmp(cmd, "write-loop") == 0 && arg_count == 2) {
        rc = cmd_write_loop(args[0], args[1]);
    } else if (strcmp(cmd, "rw-loop") == 0 && arg_count <= 1) {
        rc = cmd_rw_loop(args[0]);
    } else {
        usage(argv[0]);
        rc = EXIT_USAGE;
    }

    /* Cierro el mapeo antes de salir. */
    unmap_hw();
    return rc;
}
