#include <stdio.h>
#include <include/labwork.h>
#include <cuda_runtime_api.h>
#include <omp.h>

#define ACTIVE_THREADS 4

int main(int argc, char **argv) {
    printf("USTH ICT Master 2018, Advanced Programming for HPC.\n");
    if (argc < 2) {
        printf("Usage: labwork <lwNum> <inputImage>\n");
        printf("   lwNum        labwork number\n");
        printf("   inputImage   the input file name, in JPEG format\n");
        return 0;
    }

    int lwNum = atoi(argv[1]);
    std::string inputFilename;

    // pre-initialize CUDA to avoid incorrect profiling
    printf("Warming up...\n");
    char *temp;
    cudaMalloc(&temp, 1024);

    Labwork labwork;
    if (lwNum != 2 ) {
        inputFilename = std::string(argv[2]);
        labwork.loadInputImage(inputFilename);
    }

    printf("Starting labwork %d\n", lwNum);
    Timer timer;
    timer.start();
    switch (lwNum) {
        case 1:
            timer.start();
            labwork.labwork1_CPU();
            labwork.saveOutputImage("labwork2-cpu-out.jpg");
            printf("labwork 1 CPU ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            timer.start();
            labwork.labwork1_OpenMP();
            labwork.saveOutputImage("labwork2-openmp-out.jpg");
            printf("labwork 1 GPU ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            break;
        case 2:
            labwork.labwork2_GPU();
            break;
        case 3:
            labwork.labwork3_GPU();
            labwork.saveOutputImage("labwork3-gpu-out.jpg");
            printf("labwork 3 GPU CUDA ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            break;
        case 31:    // See difference with OpenMP
            timer.start();
            labwork.labwork1_OpenMP();
            labwork.saveOutputImage("labwork3-openmp-out.jpg");
            printf("labwork 1 GPU ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            timer.start();
            labwork.labwork3_GPU();
            labwork.saveOutputImage("labwork3-gpu-out.jpg");
            printf("labwork 3 GPU CUDA ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            break;
        case 4:
            timer.start();
            labwork.labwork4_GPU();
            labwork.saveOutputImage("labwork4-gpu-out.jpg");
            printf("labwork 4 GPU CUDA 2D Blocks ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            break;
        case 41:    // See difference with OpenMP
            timer.start();
            labwork.labwork1_OpenMP();
            labwork.saveOutputImage("labwork4-openmp-out.jpg");
            printf("labwork 1 GPU ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            timer.start();
            labwork.labwork4_GPU();
            labwork.saveOutputImage("labwork4-gpu-out.jpg");
            printf("labwork 4 GPU CUDA 2D Blocks ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            break;
        case 42:    // See difference with OpenMP
            timer.start();
            labwork.labwork3_GPU();
            labwork.saveOutputImage("labwork4-gpu-out.jpg");
            printf("labwork 3 GPU CUDA ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            timer.start();
            labwork.labwork4_GPU();
            labwork.saveOutputImage("labwork4-gpu-out.jpg");
            printf("labwork 4 GPU CUDA 2D Blocks ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            break;
        case 5:
            labwork.labwork5_CPU();
            printf("labwork 5 CPU ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            labwork.saveOutputImage("labwork5-cpu-out.jpg");
            timer.start();
            labwork.labwork5_GPU(false);
            printf("labwork 5 GPU non-shared memory ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            labwork.saveOutputImage("labwork5-gpu-nms-out.jpg");
            timer.start();
            labwork.labwork5_GPU(true);
            printf("labwork 5 GPU shared memory ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
            labwork.saveOutputImage("labwork5-gpu-ms-out.jpg");
            break;
        case 6:
            if (lwNum != 3 ) {
                labwork.loadInputSecondImage( std::string(argv[3]) );
            }
            labwork.labwork6_GPU();
            labwork.saveOutputImage("labwork6-gpu-out.jpg");
            break;
        case 7:
            labwork.labwork7_GPU();
            labwork.saveOutputImage("labwork7-gpu-out.jpg");
            break;
        case 8:
            labwork.labwork8_GPU();
            labwork.saveOutputImage("labwork8-gpu-out.jpg");
            break;
        case 9:
            labwork.labwork9_GPU();
            labwork.saveOutputImage("labwork9-gpu-out.jpg");
            break;
        case 10:
            labwork.labwork10_GPU();
            labwork.saveOutputImage("labwork10-gpu-out.jpg");
            break;
    }
    printf("labwork %d ellapsed %.1fms\n", lwNum, timer.getElapsedTimeInMilliSec());
}

void Labwork::loadInputImage(std::string inputFileName) {
    inputImage = jpegLoader.load(inputFileName);
}

void Labwork::loadInputSecondImage(std::string inputFileName) {
    inputSecondImage = jpegLoader.load(inputFileName);
}

void Labwork::saveOutputImage(std::string outputFileName) {
    jpegLoader.save(outputFileName, outputImage, inputImage->width, inputImage->height, 90);
}

void Labwork::labwork1_CPU() {
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
    for (int j = 0; j < 100; j++) {     // let's do it 100 times, otherwise it's too fast!
        for (int i = 0; i < pixelCount; i++) {
            outputImage[i * 3] = (char) (((int) inputImage->buffer[i * 3] + (int) inputImage->buffer[i * 3 + 1] +
                                          (int) inputImage->buffer[i * 3 + 2]) / 3);
            outputImage[i * 3 + 1] = outputImage[i * 3];
            outputImage[i * 3 + 2] = outputImage[i * 3];
        }
    }
}

void Labwork::labwork1_OpenMP() {
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));

    #pragma omp parallel for
    for (int j = 0; j < 100; j++) {     // let's do it 100 times, otherwise it's too fast!
        #pragma omp parallel for
        for (int i = 0; i < pixelCount; i++) {
            outputImage[i * 3] = (char) (((int) inputImage->buffer[i * 3] + (int) inputImage->buffer[i * 3 + 1] +
                                          (int) inputImage->buffer[i * 3 + 2]) / 3);
            outputImage[i * 3 + 1] = outputImage[i * 3];
            outputImage[i * 3 + 2] = outputImage[i * 3];
        }
    }
}

int getSPcores(cudaDeviceProp devProp) {
    int cores = 0;
    int mp = devProp.multiProcessorCount;
    switch (devProp.major) {
        case 2: // Fermi
            if (devProp.minor == 1) cores = mp * 48;
            else cores = mp * 32;
            break;
        case 3: // Kepler
            cores = mp * 192;
            break;
        case 5: // Maxwell
            cores = mp * 128;
            break;
        case 6: // Pascal
            if (devProp.minor == 1) cores = mp * 128;
            else if (devProp.minor == 0) cores = mp * 64;
            else printf("Unknown device type\n");
            break;
        default:
            printf("Unknown device type\n");
            break;
    }
    return cores;
}

//Get to know your GPU
void Labwork::labwork2_GPU() {
    int nDevices = 0;
    // get all devices
    cudaGetDeviceCount(&nDevices);
    printf("Number total of GPU : %d\n\n", nDevices);
    for (int i = 0; i < nDevices; i++){
        //get informations from individual device
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, i);

        //Device info
        //=================
        printf("Device Number : %d\n", i);
        printf("Device Name : %s\n", prop.name);

        //Core info
        //=================
        //clock rate
        printf("\tClock Rate (KHz): %f\n", prop.clockRate);
        //core counts
        printf("\tCore Number : %d\n", getSPcores(prop));
        //multiprocessor count
        printf("\tMultiprocessor Number : %d\n", prop.multiProcessorCount);
        //warp size
        printf("\tWarp Size : %d\n", prop.warpSize);

        //Memory info
        //=================
        //clock rate
        printf("\tMemory Clock Rate (KHz): %f\n", prop.memoryClockRate);
        //bus width 
        printf("\tMemory Bus Width (bits): %d\n", prop.memoryBusWidth);
        //[optional] bandwidth
        printf("\tPeak Memory Bandwidth (GB/s): %f\n\n", 2.0*prop.memoryClockRate*(prop.memoryBusWidth/8)/1.0e6);
    }

}

__global__ void grayscale(uchar3 *input, uchar3 *output) {
    int tid = threadIdx.x + blockIdx.x * blockDim.x;
    output[tid].x = (input[tid].x + input[tid].y + input[tid].z) / 3;
    output[tid].z = output[tid].y = output[tid].x;
}
//Do labwork1 with CUDA
void Labwork::labwork3_GPU() {
    // Preparing var
    //======================
    //Calculate number of pixels
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
    uchar3 *devInput;
    uchar3 *devGray;

    //Allocate CUDA memory    
    cudaMalloc(&devInput, pixelCount * sizeof(uchar3));
    cudaMalloc(&devGray, pixelCount * sizeof(uchar3));
    // Copy CUDA Memory from CPU to GPU
    cudaMemcpy(devInput, inputImage->buffer, pixelCount * sizeof(uchar3), cudaMemcpyHostToDevice);

    // Processing
    //======================
    // Start GPU processing (KERNEL)
    int blockSize = 1024;
    int numBlock = pixelCount / blockSize;
    grayscale<<<numBlock, blockSize>>>(devInput, devGray);
    // Copy CUDA Memory from GPU to CPU
    cudaMemcpy(outputImage, devGray, pixelCount * sizeof(uchar3), cudaMemcpyDeviceToHost);

    // Cleaning
    //======================
    // Free CUDA Memory
    cudaFree(&devInput);
    cudaFree(&devGray);
}

__global__ void grayscale2D(uchar3 *input, uchar3 *output, int imgWidth, int imgHeight) {
    //Calculate tid
    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if (tidx >= imgWidth || tidy >= imgHeight) return;

    int tid =  tidx + (tidy * imgWidth);

    //Process pixel
    output[tid].x = (input[tid].x + input[tid].y + input[tid].z) / 3;
    output[tid].z = output[tid].y = output[tid].x;
}
//Improve labwork 3 code to use 2D blocks
void Labwork::labwork4_GPU() {
    // Preparing var
    //======================
    //Calculate number of pixels
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
    uchar3 *devInput;
    uchar3 *devGray;

    //Allocate CUDA memory    
    cudaMalloc(&devInput, pixelCount * sizeof(uchar3));
    cudaMalloc(&devGray, pixelCount * sizeof(uchar3));
    // Copy CUDA Memory from CPU to GPU
    cudaMemcpy(devInput, inputImage->buffer, pixelCount * sizeof(uchar3), cudaMemcpyHostToDevice);

    // Processing
    //======================
    // Start GPU processing (KERNEL)
    //Create 32x32 Blocks
    dim3 blockSize = dim3(32, 32);
    dim3 gridSize = dim3((inputImage->width + (blockSize.x-1))/blockSize.x, 
        (inputImage->height  + (blockSize.y-1))/blockSize.y);
    grayscale2D<<<gridSize, blockSize>>>(devInput, devGray, inputImage->width, inputImage->height);
    // Copy CUDA Memory from GPU to CPU
    cudaMemcpy(outputImage, devGray, pixelCount * sizeof(uchar3), cudaMemcpyDeviceToHost);

    // Cleaning
    //======================
    // Free CUDA Memory
    cudaFree(&devInput);
    cudaFree(&devGray);
}

// CPU implementation of Gaussian Blur
void Labwork::labwork5_CPU() {
    int kernel[] = { 0, 0, 1, 2, 1, 0, 0,  
                     0, 3, 13, 22, 13, 3, 0,  
                     1, 13, 59, 97, 59, 13, 1,  
                     2, 22, 97, 159, 97, 22, 2,  
                     1, 13, 59, 97, 59, 13, 1,  
                     0, 3, 13, 22, 13, 3, 0,
                     0, 0, 1, 2, 1, 0, 0 };
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = (char*) malloc(pixelCount * sizeof(char) * 3);
    for (int row = 0; row < inputImage->height; row++) {
        for (int col = 0; col < inputImage->width; col++) {
            int sum = 0;
            int c = 0;
            for (int y = -3; y <= 3; y++) {
                for (int x = -3; x <= 3; x++) {
                    int i = col + x;
                    int j = row + y;
                    if (i < 0) continue;
                    if (i >= inputImage->width) continue;
                    if (j < 0) continue;
                    if (j >= inputImage->height) continue;
                    int tid = j * inputImage->width + i;
                    unsigned char gray = (inputImage->buffer[tid * 3] + inputImage->buffer[tid * 3 + 1] + inputImage->buffer[tid * 3 + 2])/3;
                    int coefficient = kernel[(y+3) * 7 + x + 3];
                    sum = sum + gray * coefficient;
                    c += coefficient;
                }
            }
            sum /= c;
            int posOut = row * inputImage->width + col;
            outputImage[posOut * 3] = outputImage[posOut * 3 + 1] = outputImage[posOut * 3 + 2] = sum;
        }
    }
}

__global__ void GaussianBlur(uchar3 *input, uchar3 *output, int imgWidth, int imgHeight){


    int kernel[] = { 0, 0, 1, 2, 1, 0, 0,  
                     0, 3, 13, 22, 13, 3, 0,  
                     1, 13, 59, 97, 59, 13, 1,  
                     2, 22, 97, 159, 97, 22, 2,  
                     1, 13, 59, 97, 59, 13, 1,  
                     0, 3, 13, 22, 13, 3, 0,
                     0, 0, 1, 2, 1, 0, 0 };

    //Calculate tid
    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if (tidx >= imgWidth || tidy >= imgHeight) return;

    int sum = 0;
    int c = 0;
    for (int y = -3; y <= 3; y++) {
        for (int x = -3; x <= 3; x++) {
            int i = tidx + x;
            int j = tidy + y;
            
            //We won't take pixel outside of the image.
            if (i < 0) continue;
            if (i >= imgWidth) continue;
            if (j < 0) continue;
            if (j >= imgHeight) continue;
            
            int tid = imgWidth * j + i; // RowSize * j + i, get the position of our pixel
            
            //Applying gray filter
            unsigned char gray = (input[tid].x + input[tid].y + input[tid].z) / 3;
            
            //Applying Gaussian blur and stuff
            int coefficient = kernel[(y+3) * 7 + x + 3];
            sum = sum + gray * coefficient;
            c += coefficient;
        }
    }

    sum /= c;
    int posOut = tidx + tidy * imgWidth;
    output[posOut].y = output[posOut].x = output[posOut].z = sum;

}
__global__ void sharedGaussianBlur(uchar3 *input, uchar3 *output, int imgWidth, int imgHeight, int *kernelMatrix){

    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if (tidx >= imgWidth || tidy >= imgHeight) return;

    // Get thread's index number inside the block
    int tid = threadIdx.x + threadIdx.y * blockDim.x;

    __shared__ int sharedKernel[49]; 

    // Fill shared array
    if (tid < 49)
        sharedKernel[tid] = kernelMatrix[tid];

    // Wait shared array to be completed
    __syncthreads();    

    // Core function
    //======================
    int sum = 0;
    int c = 0;
    for (int y = -3; y <= 3; y++) {
        for (int x = -3; x <= 3; x++) {
            int i = tidx + x;
            int j = tidy + y;
            
            //We won't take pixel outside of the image.
            if (i < 0) continue;
            if (i >= imgWidth) continue;
            if (j < 0) continue;
            if (j >= imgHeight) continue;
            
            tid = imgWidth * j + i; // RowSize * j + i, get the position of our pixel
            
            //Applying gray filter
            unsigned char gray = (input[tid].x + input[tid].y + input[tid].z) / 3;
            
            //Applying Gaussian blur and stuff
            int coefficient = sharedKernel[(y+3) * 7 + x + 3];
            sum = sum + gray * coefficient;
            c += coefficient;
        }
    }

    sum /= c;
    int posOut = tidx + tidy * imgWidth;
    output[posOut].y = output[posOut].x = output[posOut].z = sum;

}
void Labwork::labwork5_GPU(bool shared) {
    // var
    //======================
    int kernel[] = { 0, 0, 1, 2, 1, 0, 0,  
                     0, 3, 13, 22, 13, 3, 0,  
                     1, 13, 59, 97, 59, 13, 1,  
                     2, 22, 97, 159, 97, 22, 2,  
                     1, 13, 59, 97, 59, 13, 1,  
                     0, 3, 13, 22, 13, 3, 0,
                     0, 0, 1, 2, 1, 0, 0 };

    int pixelCount = inputImage->width * inputImage->height;
    outputImage = (char*) malloc(pixelCount * sizeof(char) * 3);

    // GPU Var
    uchar3 *devInput;
    uchar3 *devGray;
    int *gpuKernel;
    //Allocate CUDA memory    
    cudaMalloc(&devInput, pixelCount * sizeof(uchar3));
    cudaMalloc(&devGray, pixelCount * sizeof(uchar3));
    cudaMalloc(&gpuKernel, sizeof(kernel));
    // Copy CUDA Memory from CPU to GPU
    cudaMemcpy(devInput, inputImage->buffer, pixelCount * sizeof(uchar3), cudaMemcpyHostToDevice);
    cudaMemcpy(gpuKernel, kernel, sizeof(kernel), cudaMemcpyHostToDevice);

    // Processing
    //======================
    // Start GPU processing (KERNEL)
    //Create 32x32 Blocks
    dim3 blockSize = dim3(32, 32);
    dim3 gridSize = dim3((inputImage->width + (blockSize.x-1))/blockSize.x, 
        (inputImage->height  + (blockSize.y-1))/blockSize.y);
    if (shared){
        sharedGaussianBlur<<<gridSize, blockSize>>>(devInput, devGray, inputImage->width, inputImage->height, gpuKernel);
    } else {
        GaussianBlur<<<gridSize, blockSize>>>(devInput, devGray, inputImage->width, inputImage->height);
    }
    // Copy CUDA Memory from GPU to CPU
    cudaMemcpy(outputImage, devGray, pixelCount * sizeof(uchar3), cudaMemcpyDeviceToHost);

    // Cleaning
    //======================
    // Free CUDA Memory
    cudaFree(&devInput);
    cudaFree(&devGray);
    cudaFree(&gpuKernel);
}

//labwork6a
__global__ void binarize(uchar3 *input, uchar3 *output, int imgWidth, int imgHeight) {
    //Calculate tid
    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if (tidx >= imgWidth || tidy >= imgHeight) return;

    int tid =  tidx + (tidy * imgWidth);

    //Process pixel
    output[tid].z = output[tid].y = output[tid].x = (((int)(input[tid].x + input[tid].y + input[tid].z) / 3)/127)*255;
}
//labwork6b
__global__ void brightnessControll(uchar3 *input, uchar3 *output, int imgWidth, int imgHeight, int value) {
    //Calculate tid
    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if (tidx >= imgWidth || tidy >= imgHeight) return;

    int tid =  tidx + (tidy * imgWidth);

    //Process pixel
    output[tid].x = min(255, max(0, input[tid].x + value));
    output[tid].y = min(255, max(0, input[tid].y + value));
    output[tid].z = min(255, max(0, input[tid].z + value));  
}
//labwork6c
__global__ void blendingImg(uchar3 *input, uchar3 *output, int imgWidth, int imgHeight, uchar3 *secondImg, double weight) {
    //Calculate tid
    int tidx = threadIdx.x + blockIdx.x * blockDim.x;
    int tidy = threadIdx.y + blockIdx.y * blockDim.y;
    if (tidx >= imgWidth || tidy >= imgHeight) return;

    int tid =  tidx + (tidy * imgWidth);

    //Process pixel
    output[tid].x = (weight * (double)input[tid].x) + ((1.0 - weight) * (double)secondImg[tid].x);
    output[tid].y = (weight * (double)input[tid].y) + ((1.0 - weight) * (double)secondImg[tid].y);
    output[tid].z = (weight * (double)input[tid].z) + ((1.0 - weight) * (double)secondImg[tid].z);
}
void Labwork::labwork6_GPU() {
    // Preparing var
    //======================
    //Calculate number of pixels
    int pixelCount = inputImage->width * inputImage->height;
    outputImage = static_cast<char *>(malloc(pixelCount * 3));
    uchar3 *devInput;
    uchar3 *devImgProcessed;

    //Allocate CUDA memory    
    cudaMalloc(&devInput, pixelCount * sizeof(uchar3));
    cudaMalloc(&devImgProcessed, pixelCount * sizeof(uchar3));
    // Copy CUDA Memory from CPU to GPU
    cudaMemcpy(devInput, inputImage->buffer, pixelCount * sizeof(uchar3), cudaMemcpyHostToDevice);

    // Processing
    //======================
    // Start GPU processing (KERNEL)
    //Create 32x32 Blocks
    dim3 blockSize = dim3(32, 32);
    dim3 gridSize = dim3((inputImage->width + (blockSize.x-1))/blockSize.x, 
        (inputImage->height  + (blockSize.y-1))/blockSize.y);
    
    //labwork6a
    //binarize<<<gridSize, blockSize>>>(devInput, devImgProcessed, inputImage->width, inputImage->height);
    
    //labwork6b
    //brightnessControll<<<gridSize, blockSize>>>(devInput, devImgProcessed, inputImage->width, inputImage->height, 50);
    
    //labwork6c
    uchar3 *secondImg;

    cudaMalloc(&secondImg, pixelCount * sizeof(uchar3));
    cudaMemcpy(secondImg, inputSecondImage->buffer, pixelCount * sizeof(uchar3), cudaMemcpyHostToDevice);

    blendingImg<<<gridSize, blockSize>>>(devInput, devImgProcessed, inputImage->width, inputImage->height, secondImg, 0.5);

    // Copy CUDA Memory from GPU to CPU
    cudaMemcpy(outputImage, devImgProcessed, pixelCount * sizeof(uchar3), cudaMemcpyDeviceToHost);

    // Cleaning
    //======================
    // Free CUDA Memory
    cudaFree(&devInput);
    cudaFree(&devImgProcessed);
    cudaFree(&secondImg);
}
void Labwork::labwork7_GPU() {

}

void Labwork::labwork8_GPU() {

}

void Labwork::labwork9_GPU() {

}

void Labwork::labwork10_GPU() {

}
