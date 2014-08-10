#!awk -f
# Befunge interpreter in AWK

BEGIN {
        srand()
        FS=""

        # Le Grid
        MAXGRIDX=80
        MAXGRIDY=25
        for(x=1; x<=MAXGRIDX; x++) {
            for(y=1; y<=MAXGRIDY; y++) {
                GRID[x,y] = " ";
            }
        }

        # IP: Instruction Pointer
        IPX=1
        IPY=1

        DIR=">"

        # Stack Pointer

        STACK[1] = ""
        STACKPTR = 0;

        ASCIIMODE = 0;
        RUNNING = 1;

        _ord_init()
}

# Populate the grid
NR <= MAXGRIDY { 
    for(x=1; x<=NF && x<=MAXGRIDX; x++) {
        GRID[x,NR]=$x
    }
}

END { 
    do {
        INS=get_ins(IPX, IPY);
        if (INS != -1) {
            if (ASCIIMODE) {
                run();
            } else if (index("^>v<", INS)) {
                DIR=INS;
            } else if (INS == "?") {
                DIR=randdir();
            } else {
                run();
            }
        }
        # printf("IPX: %d,IPY: %d, INS: %s, DIR: %s, STACKPTR: %d\n",  IPX, IPY, INS, DIR, STACKPTR);
        set_ip();

        if (DEBUG == 1) {
            system("sleep 0.01; clear");
            for(y=1; y<=MAXGRIDY; y++) {
                for(x=1; x<=MAXGRIDX; x++) {
                    if (IPX == x && IPY == y) {
                        printf("%c[%d;%dm%s%c[%dm", 27, 7, 37, GRID[x,y], 27, 0);
                    } else {
                        printf(GRID[x,y]);
                    }
                }
                print ""
            }
        }

    } while (RUNNING == 1);

}

function get_ins(x, y) {
    return GRID[x, y];
}

function set_ip() {
    if (DIR==">") {
        if (IPX==MAXGRIDX) IPX=0;
        IPX++;
    } else if (DIR=="<") {
        if (IPX==1) IPX=MAXGRIDX+1;
        IPX--;
    } else if (DIR=="^") {
        if (IPY==1) IPY=MAXGRIDY+1;
        IPY--;
    } else if (DIR=="v") {
        if (IPY==MAXGRIDY) IPY=0;
        IPY++;
    } else {
        print "Unknown direction:", DIR
    }
}

function run() {
    if (ASCIIMODE==1) {
        if (INS == "\"") {
            ASCIIMODE=0;
        } else {
            push_char(INS);
        }
    } else if (INS == "\"") {
        ASCIIMODE=1;
    } else if (match(INS, "[0-9]")) {
        push_int(INS);
    } else if (match(INS, "[a-f]")) {
        push_int(ord(INS) - 87);
    } else if (INS == ",") {
        printf("%s", chr(pop()));
    } else if (INS == ".") {
        printf("%d", pop());
    } else if (INS == "*") {
        push_int(pop()*pop());
    } else if (INS == "+") {
        push_int(pop()+pop());
    } else if (INS == "-") {
        push_int(pop()-pop());
    } else if (INS == "/") {
        a = pop()
        b = pop()
        if (b == 0) {
            push_int(0);
        } else {
            push_int(a/b);
        }
    } else if (INS == "%") {
        push_int(pop()%pop());
    } else if (INS == "#") {
        set_ip();  /* Trampoline. Skip next cell */
    } else if (INS == "_") {
        if (pop() == 0) {
            DIR=">";
        } else {
            DIR="<";
        }
    } else if (INS == "|") {
        if (pop() == 0) {
            DIR="v";
        } else {
            DIR="^";
        }
    } else if (INS == "`") {
        a = pop();
        b = pop();
        if (b>a) {
            push_int(1);
        } else {
            push_int(0);
        }
    } else if (INS == "!") {
        if (pop() == 0) {
            push_int(1);
        } else {
            push_int(0);
        }
    } else if (INS == ":") {
        val = pop();
        push_int(val);
        push_int(val);
    } else if (INS == "$") {
        pop();
    } else if (INS == "\\") {
        a = pop();
        b = pop();
        push_int(a);
        push_int(b);
    } else if (INS == " ") {
        /* Do nothing */
    } else if (INS == "@") {
        RUNNING = 0;
    } else if (INS == "&") {
        getline input < "/dev/tty";
        push_int(gsub(/[^0-9]/, "", input));
    } else if (INS == "~") {
        "bash -c 'read -s -r -N1 buf; echo -n $buf'" | getline input
        close("bash -c 'read -s -r -N1 buf; echo -n $buf'");
        push_int(ord(input));
    } else if (INS == "p") {
        y = pop();
        x = pop();
        v = pop();
        GRID[x,y] = v;
    } else if (INS == "g") {
        y = pop();
        x = pop();
        push_int(ord(GRID[x,y]));
    } else {
        printf("\nUnknown instruction: '%s'\n", INS);
    }

}

function push_int(val) {
    STACK[STACKPTR++] = int(val);
}

function push_char(val) {
    STACK[STACKPTR++] = ord(val);
}

function pop() {
    if (STACKPTR > 0) {
        return STACK[--STACKPTR];
    } else {
        return 0;
    }
}

# http://www.math.utah.edu/docs/info/gawk_toc.html#SEC145
function _ord_init(    low, high, i, t)
{
    low = sprintf("%c", 7) # BEL is ascii 7
    if (low == "\a") {    # regular ascii
        low = 0
        high = 127
    } else if (sprintf("%c", 128 + 7) == "\a") {
        # ascii, mark parity
        low = 128
        high = 255
    } else {        # ebcdic(!)
        low = 0
        high = 255
    }

    for (i = low; i <= high; i++) {
        t = sprintf("%c", i)
        _ord_[t] = i
    }
}

function ord(str,    c)
{
    # only first character is of interest
    c = substr(str, 1, 1)
    return _ord_[c]
}

function chr(c)
{
    # force c to be numeric by adding 0
    return sprintf("%c", c + 0)
}

function randdir()
{
    s = rand();
    if (s<0.25) {
        return "<";
    } else if (s<0.5) {
        return "^";
    } else if (s<0.75) {
        return ">";
    } else {
        return "v";
    }
}
