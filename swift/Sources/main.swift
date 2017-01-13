import Foundation
import Glibc
import GlibcExtras

let maxBuffer = 1000
let maxEvents: Int32 = 5

let EPOLLIN_UINT32 = unsafeBitCast(EPOLLIN, to: UInt32.self)
let EPOLLHUP_UINT32 = unsafeBitCast(EPOLLHUP, to: UInt32.self)
let EPOLLERR_UINT32 = unsafeBitCast(EPOLLERR, to: UInt32.self)

if Process.arguments.count == 1 {
  print("Usage: \(Process.arguments[0]) file...")
  exit(1)
}

let epfd = epoll_create1(0)
if epfd == -1 {
  fatalError("epoll_create1")
}

var ev = epoll_event()

for arg in 1 ... Process.arguments.count-1 {
  let fname = Process.arguments[arg]
  let fd = open(fname, O_RDONLY)
  if fd == -1 {
    fatalError("open")
  }
  print("Opened \(fname) on fd \(fd)")

  ev.events = EPOLLIN_UINT32
  ev.data.fd = fd
  if epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev) == -1 {
    perror("epoll_ctl")
    abort()
  }
}

var numOpenFds = Process.arguments.count-1

var evlist = UnsafeMutablePointer<epoll_event>(allocatingCapacity: Int(maxEvents))

let buffer = [CChar](repeating: 0, count: maxBuffer)
let buf = UnsafeMutablePointer<CChar>(buffer)

while numOpenFds > 0 {
  print("About to epoll_wait()")
  let ready = Int(epoll_wait(epfd, evlist, maxEvents, -1))
  if ready == -1 {
    if errno == EINTR {
      continue
    } else {
      perror("epoll_wait")
      abort()
    }
  }
  print("Ready \(ready)")
  for i in 0 ..< ready {
    let event = evlist[i]
    //dump(event)
    print("  fd=\(event.data.fd), events: " + 
      (event.events & EPOLLIN_UINT32 > 0 ? "EPOLLIN " : "") +
      (event.events & EPOLLHUP_UINT32 > 0 ? "EPOLLHUP " : "") +
      (event.events & EPOLLERR_UINT32 > 0 ? "EPOLLERR " : "")) 
      
    if event.events & EPOLLIN_UINT32 > 0 {
      let s = read(event.data.fd, buf, maxBuffer)
      if s == -1 {
        perror("read")
        abort()
      }
      if let str = String(data: NSData(bytes: buffer, length: s), encoding: NSASCIIStringEncoding) {
        print("  read: \(s) bytes: \(str))")
      }
    } else if evlist[i].events & (EPOLLHUP_UINT32 | EPOLLERR_UINT32) > 0 {
      print("  closing fd \(event.data.fd)")
      if close(event.data.fd) == -1 {
        perror("close")
        abort()
      }
      numOpenFds -= 1
    }
  }
}

print("All file descriptors closed; bye")
