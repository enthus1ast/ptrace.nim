import posix

{.pragma: c,
 importc,
 header: "sys/ptrace.h"
.}

type
  Registers* = object
    r15*: culong
    r14*: culong
    r13*: culong
    r12*: culong
    rbp*: culong
    rbx*: culong
    r11*: culong
    r10*: culong
    r9*: culong
    r8*: culong
    rax*: culong
    rcx*: culong
    rdx*: culong
    rsi*: culong
    rdi*: culong
    orig_rax*: culong
    rip*: culong
    cs*: culong
    eflags*: culong
    rsp*: culong
    ss*: culong
    fs_base*: culong
    gs_base*: culong
    ds*: culong
    es*: culong
    fs*: culong
    gs*: culong

var
  PTRACE_TRACEME* {.c.}: cint
  PTRACE_PEEKTEXT* {.c.}: cint
  PTRACE_PEEKDATA* {.c.}: cint
  PTRACE_PEEKUSER* {.c.}: cint
  PTRACE_POKETEXT* {.c.}: cint
  PTRACE_POKEDATA* {.c.}: cint
  PTRACE_POKEUSER* {.c.}: cint
  PTRACE_CONT* {.c.}: cint
  PTRACE_KILL* {.c.}: cint
  PTRACE_SINGLESTEP* {.c.}: cint
  PTRACE_GETREGS* {.c.}: cint
  PTRACE_SETREGS* {.c.}: cint
  PTRACE_GETFPREGS* {.c.}: cint
  PTRACE_SETFPREGS* {.c.}: cint
  PTRACE_ATTACH* {.c.}: cint
  PTRACE_DETACH* {.c.}: cint
  PTRACE_GETFPXREGS* {.c.}: cint
  PTRACE_SETFPXREGS* {.c.}: cint
  PTRACE_SYSCALL* {.c.}: cint
  PTRACE_SETOPTIONS* {.c.}: cint
  PTRACE_GETEVENTMSG* {.c.}: cint
  PTRACE_GETSIGINFO* {.c.}: cint
  PTRACE_SETSIGINFO* {.c.}: cint
  PTRACE_SEIZE* {.c.}: cint
  PTRACE_INTERRUPT* {.c.}: cint
  PTRACE_LISTEN* {.c.}: cint



const
  PTRACE_EVENT_FORK* = 1
  PTRACE_EVENT_VFORK* = 2
  PTRACE_EVENT_CLONE* = 3
  PTRACE_EVENT_EXEC* = 4
  PTRACE_EVENT_VFORK_DONE* =  5
  PTRACE_EVENT_EXIT* = 6
  PTRACE_EVENT_SECCOMP* = 7
  PTRACE_EVENT_STOP* = 128


  PTRACE_O_TRACESYSGOOD* = 1
  PTRACE_O_TRACEFORK* = 1 shl PTRACE_EVENT_FORK
  PTRACE_O_TRACEVFORK* = 1 shl PTRACE_EVENT_VFORK
  PTRACE_O_TRACECLONE* = 1 shl PTRACE_EVENT_CLONE
  PTRACE_O_TRACEEXEC* = 1 shl PTRACE_EVENT_EXEC
  PTRACE_O_TRACEVFORKDONE* = 1 shl PTRACE_EVENT_VFORK_DONE
  PTRACE_O_TRACEEXIT* = 1 shl PTRACE_EVENT_EXIT
  PTRACE_O_TRACESECCOMP* = 1 shl PTRACE_EVENT_SECCOMP
  PTRACE_O_EXITKILL* = 1 shl 20
  PTRACE_O_MASK* = 0x000000ff or PTRACE_O_EXITKILL


when hostCPU == "i386":
  const
    EBX* = 0
    ECX* = 1
    EDX* = 2
    ESI* = 3
    EDI* = 4
    EBP* = 5
    EAX* = 6
    DS* = 7
    ES* = 8
    FS* = 9
    GS* = 10
    ORIG_EAX* = 11
    EIP* = 12
    CS* = 13
    EFL* = 14
    UESP* = 15
    SS* =16
else:
  const
    R15* = 0
    R14* = 8
    R13* = 16
    R12* = 24
    RBP* = 32
    RBX* = 40
    R11* = 48
    R10* = 56
    R9* = 64
    R8* = 72
    RAX* = 80
    RCX* = 88
    RDX* = 96
    RSI* = 104
    RDI* = 112
    ORIG_RAX* = 120
    RIP* = 128
    CS* = 136
    EFLAGS* = 144
    RSP* = 152
    SS* = 160
    FS_BASE* = 168
    GS_BASE* = 176
    DS* = 184
    ES* = 192
    FS* = 200
    GS* = 208

proc ptrace*(request: cint, pid: Pid, a: cint, data: pointer): clong {.c.}

template setOptions*(p: Pid, opts: ptr cint): expr =
  ptrace(PTRACE_SETOPTIONS, p, 0, opts)

proc getRegs*(p: int): Registers {.inline.} =
  discard ptrace(PTRACE_GETREGS, p, 0, addr result)

template setRegs*(p: Pid, regs: ptr Registers): expr =
  ptrace(PTRACE_SETREGS, p, 0, regs)

template attach*(p: Pid): expr =
  ptrace(PTRACE_ATTACH, p, 0, nil)

template detach*(p: Pid, signal: ptr cint): expr =
  ptrace(PTRACE_DETACH, p, 0, signal)

template cont*(p: Pid, signal: ptr cint): expr =
  ptrace(PTRACE_CONT, p, 0, signal)

template traceme*(): expr =
  ptrace(PTRACE_TRACEME, 0, 0, nil)

when isMainModule:
  var child: Pid;
  var orig_ax: clong;

  child = fork()
  if child == 0:
    discard traceme()
    discard execl("/bin/ls", "ls", nil)

  else:
    var a: cint
    discard wait(a)

    var regs = getRegs(child)
    echo "orig_rax: ", regs.orig_rax
    if errno != 0:
      echo errno, " ", strerror(errno)

    orig_ax = ptrace(PTRACE_PEEKUSER, child, ORIG_RAX, nil)
    if errno != 0:
      echo errno, " ", strerror(errno)
    echo "The child made a system call: ", orig_ax
    discard cont(child, nil)