#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

int cache_size; //cache_size = blocks * block_size
int block_size;
int associativity; //0=direct mapped 1=four-way associative2=fully associative
int replace_algorithm; //0=FIFO 1=LRU
int memory_bits = 32;
char buffer[10];

void covert_hex_to_binary(char hex_address[],char binary_address[])
{
    for(int i=2;i<10;i++)
    {
        switch(hex_address[i])
        {
            case '0':
                strcat(binary_address, "0000");
                break;
            case '1':
                strcat(binary_address, "0001");
                break;
            case '2':
                strcat(binary_address, "0010");
                break;
            case '3':
                strcat(binary_address, "0011");
                break;
            case '4':
                strcat(binary_address, "0100");
                break;
            case '5':
                strcat(binary_address, "0101");
                break;
            case '6':
                strcat(binary_address, "0110");
                break;
            case '7':
                strcat(binary_address, "0111");
                break;
            case '8':
                strcat(binary_address, "1000");
                break;
            case '9':
                strcat(binary_address, "1001");
                break;
            case 'a':
            case 'A':
                strcat(binary_address, "1010");
                break;
            case 'b':
            case 'B':
                strcat(binary_address, "1011");
                break;
            case 'c':
            case 'C':
                strcat(binary_address, "1100");
                break;
            case 'd':
            case 'D':
                strcat(binary_address, "1101");
                break;
            case 'e':
            case 'E':
                strcat(binary_address, "1110");
                break;
            case 'f':
            case 'F':
                strcat(binary_address, "1111");
                break;
        }
    }
}

unsigned int calculate_decimal_tag(char temp_binary_address[] , int tag_bit , int index_bit , int offset_bit)
{
    char binary_address[32] = {""};
    //char binary_tag[tag_bit] = {""};
    unsigned int decimal_tag = 0;
    
    for(int i=31;i>=0;i--)
        binary_address[i] = temp_binary_address[31-i];
    
    for(int i=index_bit+offset_bit ; i<32 ; i++)
    {
        if(binary_address[i] == '1')
            decimal_tag += pow(2,i-index_bit-offset_bit);
        else
            decimal_tag += 0;
    }
    //printf("%d\n",decimal_tag);
    return decimal_tag;
}

unsigned int calculate_decimal_index(char temp_binary_address[] , int tag_bit , int index_bit , int offset_bit)
{
    char binary_address[32] = {""};
    unsigned int decimal_index = 0;
    for(int i=31;i>=0;i--)
        binary_address[i] = temp_binary_address[31-i];
    
    for(int i=offset_bit ; i<32-tag_bit ; i++)
    {
        if(binary_address[i] == '1')
            decimal_index += pow(2,i-offset_bit);
        else
            decimal_index += 0;
    }
    //printf("%d\n",decimal_tag);
    return decimal_index;
}

int result(int which_set[], int column , int tag , int replace_algorithm)// column : 一個set有幾個block
{
    if(column!= 1) //full associated or 4-way set associated
    {
        for(int i=0;i<column;i++)
        {
            if(which_set[i] == -1) //1.先看有沒有空的 有的話直接寫進去
            {
                which_set[i] = tag;
                return -1;
            }
            else if(which_set[i] == tag) //2.HIT (FIFO : 不做事) (LRU : 把該tag移動到最後面)
            {
                if(replace_algorithm == 1) //LRU
                {
                    int j;
                    int temp = tag;
                    for(j=i;j<column-1;j++)
                    {
                        if(which_set[j+1] == -1)
                            break;
                        which_set[j] = which_set[j+1];
                    }
                    which_set[j] = temp;//把tag插入
                }
                return -1;
            }
            else //往下一個block找
                continue;
        }
        //以下為MISS且空間已滿，看是哪種replace_algorithm
        if(replace_algorithm == 0) //FIFO
        {
            int victim = which_set[0];
            for(int i=1;i<column;i++)
            {
                which_set[i-1] = which_set[i];
            }
            which_set[column-1] = tag;
            return victim;
        }
        else if(replace_algorithm == 1)//LRU
        {
            int i;
            int victim = which_set[0];
            for(i=0;i<column-1;i++)
            {
                if(which_set[i+1]==-1)
                    break;
                which_set[i] = which_set[i+1];
            }
            which_set[i] = tag;
            return victim;
        }
        else//RANDOM SELECT a column and kick out
        {
            int random = rand() % column;
            int victim = which_set[random];
            which_set[random] = tag;
            return victim;
        }
    }
    else //directed map
    {
        int victim;
        if(which_set[0] == -1)
        {
            which_set[0] = tag;
            return -1;
        }
        else if(which_set[0] == tag) //hit
        {
            which_set[0] = tag;
            return -1;
        }
        victim = which_set[0]; //the tag to be kicked out of cache
        which_set[0] = tag; //new tag to be write into cache
        return victim;
    }
}

int main(int argc, char *argv[])
{
    srand(time(NULL));
    FILE *file_input, *file_output;
    //file_input = fopen(argv[1], "r");
    //file_output = fopen(argv[2], "w");
    file_input = fopen(argv[1],"r");
    file_output = fopen(argv[2],"w");
    fgets(buffer, 10, file_input);
    sscanf(buffer, "%d", &cache_size);
    fgets(buffer, 10, file_input);
    sscanf(buffer, "%d", &block_size);
    fgets(buffer, 10, file_input);
    sscanf(buffer, "%d", &associativity);
    fgets(buffer, 10, file_input);
    sscanf(buffer, "%d", &replace_algorithm);

    int row,column,answer;

    if(associativity == 0)
    {
        int tag_bit,index_bit,offset_bit,blocks;
        unsigned int tag,index,offset;
        blocks = (int)((cache_size*1024) / block_size);//block數 = cache_size / block_size
        index_bit = (int)log2(blocks);
        offset_bit = (int)log2(block_size);
        tag_bit = 32 - index_bit - offset_bit;
        row = blocks;
        column = 1;
        int cache[row][column];
        for(int i=0;i<row;i++)
        {
            for(int j=0;j<column;j++)
            {
                cache[i][j]=-1;
            }
        }
        while (fgets(buffer, 100, file_input))
        {
            unsigned int hex;
            char hex_address[10]={""};
            char binary_address[32] = {""};
            sscanf(buffer, "%s", hex_address); //在這邊讀取到address的十六進位狀態
            covert_hex_to_binary(hex_address,binary_address);
            //用address求出offset、index、tag的整數
            tag = calculate_decimal_tag(binary_address,tag_bit,index_bit,offset_bit);
            index = calculate_decimal_index(binary_address,tag_bit,index_bit,offset_bit);
            //                哪個block     哪個block
            answer = result(cache[index] , column , tag , replace_algorithm );
            fprintf(file_output,"%d\n",answer);
        }
    }

    else if(associativity == 1) //4-way sets associative
    {
        int tag_bit,index_bit,offset_bit,sets;
        unsigned int tag,index,offset;
        sets = (int)( (cache_size * (1024/4) ) / block_size ); //block數 = cache_size / block_size
        index_bit = (int)log2(sets);
        offset_bit = (int)log2(block_size);
        tag_bit = 32 - index_bit - offset_bit;
        row = sets;
        column = 4;
        int cache[row][column];
        for(int i=0;i<row;i++)
        {
            for(int j=0;j<column;j++)
            {
                cache[i][j]=-1;
            }
        }
        while (fgets(buffer, 100, file_input))
        {
            unsigned int hex;
            char hex_address[10]={""};
            char binary_address[32] = {""};
            sscanf(buffer, "%s", hex_address); //在這邊讀取到address的十六進位狀態
            covert_hex_to_binary(hex_address,binary_address);
            //用address求出offset、index、tag的整數
            tag = calculate_decimal_tag(binary_address,tag_bit,index_bit,offset_bit);
            index = calculate_decimal_index(binary_address,tag_bit,index_bit,offset_bit);
            //                哪個block     哪個block
            answer = result(cache[index] , column , tag , replace_algorithm );
            fprintf(file_output,"%d\n",answer);
        }
    }

    else if(associativity == 2)//full associative
    {
        int tag_bit,index_bit,offset_bit,sets;
        unsigned int tag,index,offset;
        sets = 1; //block數 = cache_size / block_size
        index_bit = 0;
        offset_bit = (int)log2(block_size);
        tag_bit = 32 - index_bit - offset_bit;
        row = 1;
        column = (int)(cache_size * 1024 / block_size);
        //cout<<column<<endl;
        int cache[row][column];
        for(int i=0;i<row;i++)
        {
            for(int j=0;j<column;j++)
            {
                cache[i][j]=-1;
            }
        }
        while (fgets(buffer, 100, file_input))
        {
            unsigned int hex;
            char hex_address[10]={""};
            char binary_address[32] = {""};
            sscanf(buffer, "%s", hex_address); //在這邊讀取到address的十六進位狀態
            covert_hex_to_binary(hex_address,binary_address);
            //用address求出offset、index、tag的整數
            tag = calculate_decimal_tag(binary_address,tag_bit,index_bit,offset_bit);
            index = calculate_decimal_index(binary_address,tag_bit,index_bit,offset_bit);
            //                哪個block     哪個block
            answer = result(cache[index] , column , tag , replace_algorithm );
            fprintf(file_output,"%d\n",answer);
        }
    }
    return 0;
}   