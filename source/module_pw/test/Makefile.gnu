
#==========================
# Compiler information 
#==========================
CPLUSPLUS = mpicxx
CUDA_COMPILE = nvcc
OBJ_DIR = obj
NP      = 12
LIBNAME = libpw.a
GEN     = OFF
TIME    = OFF
#==========================
# Objects
#==========================
VPATH=../../src_parallel\
:../../module_base\
:../

MATH_OBJS0=matrix.o\
matrix3.o\
tool_quit.o\
mymath3.o\
timer.o\
pw_basis.o\
pw_distributer.o\
pw_init.o\
pw_transform.o\
pw_distributeg.o\
pw_distributeg_method1.o\
pw_distributeg_method2.o\
fft.o\
pw_basis_k.o\
pw_transform_k.o

OTHER_OBJS0=global_variable.o\
parallel_global.o

DOUBLEFILE=test1-1-1.o\
test1-1-2.o\
test1-2.o\
test1-2-2.o\
test1-3.o\
test1-4.o\
test1-5.o\
test2-1-1.o\
test2-1-2.o\
test2-2.o\
test2-3.o\
test3-1.o\
test3-2.o\
test3-3.o\
test4-1.o\
test4-2.o\
test4-3.o\
test4-4.o\
test4-5.o


TESTFILE0 = ${DOUBLEFILE} 


##==========================
## FFTW package needed 
##==========================
#Use fftw package
FFTW_DIR = /home/qianrui/gnucompile/fftw_3.3.8
FFTW_LIB_DIR     = ${FFTW_DIR}/lib
FFTW_INCLUDE_DIR = ${FFTW_DIR}/include
FFTW_LIB         = -L${FFTW_LIB_DIR} -lfftw3 -lfftw3f -Wl,-rpath=${FFTW_LIB_DIR}
# FFTW_LIB         = -L${FFTW_LIB_DIR} -lfftw3 -Wl,-rpath=${FFTW_LIB_DIR}

##==========================
## GTEST needed 
##==========================
GTEST_DIR = /home/qianrui/gnucompile/g_gtest
GTESTOPTS = -I${GTEST_DIR}/include -L${GTEST_DIR}/lib -lgtest -lpthread


#==========================
# Options
#==========================
#No MPI
# HONG = -D__NORMAL
# CPLUSPLUS = g++

#Mix Precision
# HONG = -D__MIX_PRECISION -D__NORMAL
# CPLUSPLUS = g++

#Only MPI
# HONG = -D__MPI -D__NORMAL

#MPI + Mix Precision
HONG = -D__MPI -D__MIX_PRECISION -D__NORMAL

#Cuda
#HONG = -D__MPI -D__CUDA -D__NORMAL

#Cuda & Mix Precision
#HONG = -D__MPI -D__CUDA -D__MIX_PRECISION -D__NORMAL


MATH_OBJS=$(patsubst %.o, ${OBJ_DIR}/%.o, ${MATH_OBJS0})
OTHER_OBJS=$(patsubst %.o, ${OBJ_DIR}/%.o, ${OTHER_OBJS0})
TESTFILE=$(patsubst %.o, ${OBJ_DIR}/%.o, ${TESTFILE0})


##==========================
## CUDA needed 
##==========================
# CUDA_DIR = /usr/local/cuda-11.0
# CUDA_INCLUDE_DIR	= ${CUDA_DIR}/include 
# CUDA_LIB_DIR		= ${CUDA_DIR}/lib64
# CUDA_LIB			= -L${CUDA_LIB_DIR} -lcufft -lcublas -lcudart


#LIBS = ${FFTW_LIB} ${CUDA_LIB} -ltcmalloc -lprofiler
LIBS = ${FFTW_LIB} ${CUDA_LIB}
OPTS = -I${FFTW_INCLUDE_DIR} ${HONG} -Ofast -std=c++11 -Wall -g -fsanitize=address -fno-omit-frame-pointer
#==========================
# MAKING OPTIONS
#==========================
pw : 
	@ make lib
	@ make -j $(NP) pw_test.exe
	@ if [ $(GEN) == "ON" ]; then make gen.exe ; fi
	@ if [ $(TIME) == "ON" ]; then make time.exe ; fi

lib :
	@ make init
	@ make -j $(NP) $(LIBNAME)

init :
	@ if [ ! -d $(OBJ_DIR) ]; then mkdir $(OBJ_DIR); fi

$(LIBNAME): $(MATH_OBJS)
	ar -rcv $(LIBNAME) $(MATH_OBJS)

pw_test.exe: ${LIBNAME} ${OTHER_OBJS} ${TESTFILE} pw_test.cpp test_tool.cpp
	${CPLUSPLUS} ${OPTS} pw_test.cpp test_tool.cpp ${TESTFILE} ${LIBNAME} ${OTHER_OBJS} ${LIBS} -o pw_test.exe ${GTESTOPTS}

gen.exe: ${LIBNAME} ${OTHER_OBJS} generate.cpp test_tool.cpp
	${CPLUSPLUS} ${OPTS} generate.cpp test_tool.cpp $(LIBNAME) ${OTHER_OBJS} ${LIBS} -o gen.exe

time.exe: ${LIBNAME} time.cpp
	${CPLUSPLUS} ${OPTS} time.cpp $(LIBNAME)  ${LIBS} -o time.exe
	
${OBJ_DIR}/%.o:%.cpp
	${CPLUSPLUS} ${OPTS} -c ${HONG} $< -o $@ ${GTESTOPTS}

.PHONY:clean
clean:
	@ if [ -d $(OBJ_DIR) ]; then rm -rf $(OBJ_DIR); fi
	@ if [ -e $(LIBNAME) ]; then rm -f $(LIBNAME); fi
	@ if [ -e pw_test.exe ]; then rm -f pw_test.exe; fi
	@ if [ -e gen.exe ]; then rm -f gen.exe; fi
	@ if [ -e time.exe ]; then rm -f time.exe; fi