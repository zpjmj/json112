// void *jsonTestF()
// {
//     int *a;
//     *a = 1;
//     return a;
// }

main__Test jsonTestF()
{
    return (main__Test){
        .name = (string){.str = (byteptr) "", .is_lit = 1},
        .age = 15,
    };
}

// int main()
// {
//     jsonTestF();
//     return 0;
// }
