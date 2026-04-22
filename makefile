#compiler
CC = gcc

# Compiler flags
CFLAGS = -Wall -Wextra -Wno-deprecated-declarations

#Libraries
LIBS = -lssl -lcrypto

#Output binary
TARGET = myvcs

#Source files
SRC = main.c

#default rule
all:$(TARGET)

#Build binary
$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET) $(LIBS)

#installto system
install: $(TARGET)
	sudo mv $(TARGET) /usr/local/bin/

#remove from system
uninstall:
	sudo rm -f /usr/lacal/bin/$(TARGET)

clean:
	rm -f $(TARGET)

rebuild: clean all

run: $(TARGET)
	./$(TARGET)
