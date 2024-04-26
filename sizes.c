#include <stdio.h>
#include <uv.h>
#include <netinet/in.h>

int main() {
    puts("module uv_sizes");
    puts("    use iso_c_binding");
    printf("    integer(c_long), parameter :: %s = %d\n", "UV_EOF", UV_EOF);
    printf("    integer(c_size_t), parameter :: %s = %d\n", "sockaddr_in_size", sizeof(struct sockaddr_in));
    printf("    integer(c_size_t), parameter :: %s = %d\n", "uv_tcp_size", sizeof(uv_tcp_t));
    printf("    integer(c_size_t), parameter :: %s = %d\n", "uv_write_size", sizeof(uv_write_t));
    puts("end module uv_sizes");
    return 0;
}
