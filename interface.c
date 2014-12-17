/*
 * Simple code demonstrating
 * the use of NetLink.
 */
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <assert.h>
#include <ifaddrs.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <net/route.h>
#include <net/ethernet.h>

#define BUFSIZE 4096

struct _Interfaces
{
   char *name;
   char *dstaddr;
   char *gwipaddr;
   char ipaddr[INET_ADDRSTRLEN];
   char brodaddr[INET_ADDRSTRLEN];
   char hwaddr[6];
};
typedef struct _Interfaces Interfaces;

#ifndef IMAXSIZE
#define IMAXSIZE 5
#endif
static Interfaces inet[IMAXSIZE];

static char *_gateway(const char *name)
{
   struct rtmsg *route;
   struct nlmsghdr *nlmsg, *nlh;
   struct rtattr *routeattr;
   char *ptr;
   struct timeval tv;
   char msgbuf[BUFSIZE] = {0},
        buf[BUFSIZE] = {0}, interface[IF_NAMESIZE] = {0};
   static char gwaddr[INET_ADDRSTRLEN];
   ssize_t recbytes = 0, msglen = 0;
   int s, msgseq = 0, routeattr_len = 0;
   pid_t pid = getpid();

   ptr = buf;
   memset(gwaddr, 0, sizeof(gwaddr));

   if(!name)
     {
        fprintf(stderr, "invalid argument\n");
        return NULL;
     }

   s = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
   if(s == -1)
     {
        perror("socket error");
        return NULL;
     }

   nlmsg = (struct nlmsghdr *)msgbuf;

   nlmsg->nlmsg_len = NLMSG_LENGTH(sizeof(struct rtmsg));
   nlmsg->nlmsg_type = RTM_GETROUTE;
   nlmsg->nlmsg_flags = NLM_F_DUMP | NLM_F_REQUEST;
   nlmsg->nlmsg_seq = msgseq++;
   nlmsg->nlmsg_pid = pid;

   tv.tv_sec = 1;
   setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, (struct timeval *)&tv, sizeof(struct timeval));
   if(send(s, nlmsg, nlmsg->nlmsg_len, 0) == -1)
     {
        perror("send error");
        return NULL;
     }
   do 
     {
        recbytes = recv(s, buf, sizeof(buf) - msglen, 0); 
        if(recbytes == -1)
          {
             perror("recv error");
             return NULL;
          }

        nlh = (struct nlmsghdr *)ptr;
        if(!NLMSG_OK(nlmsg, recbytes) || (nlmsg->nlmsg_type == NLMSG_ERROR))
          {
             perror("packet error");
             return NULL;
          }
        
        if(nlh->nlmsg_type == NLMSG_DONE)
          break;
        
        ptr += recbytes;
        msglen += recbytes;

        if(!(nlmsg->nlmsg_flags & NLM_F_MULTI))
          break;
        
     } while((nlmsg->nlmsg_seq != msgseq) || (nlmsg->nlmsg_pid != getpid()));

   for(; NLMSG_OK(nlh, recbytes); nlh = NLMSG_NEXT(nlh, recbytes))
     {
        route = (struct rtmsg *)NLMSG_DATA(nlh);
        if(route->rtm_table != RT_TABLE_MAIN)
          continue;

        routeattr = (struct rtattr *) RTM_RTA(route);
        routeattr_len = RTM_PAYLOAD(nlh);
         
        for(; RTA_OK(routeattr, routeattr_len);
            routeattr = RTA_NEXT(routeattr, routeattr_len))
          {
             switch(routeattr->rta_type)
               {
                case RTA_OIF:
                   if_indextoname(*(int *)RTA_DATA(routeattr), interface);
                   break;
                case RTA_GATEWAY:
                   inet_ntop(AF_INET, RTA_DATA(routeattr), gwaddr, sizeof(gwaddr));
                   break;
                default:
                   break;
               }

          }
        if(*gwaddr && *interface)
          {
             if(strcmp(name, interface))
               {
                  close(s);
                  return gwaddr;
               }
        }
     }
   close(s);
   return NULL; /* error */
}

void interface_load(void)
{
   struct ifaddrs *ifap, *iftmp;
   struct sockaddr_in *sa, *bc;
   u_char *ptr;
   const char *retop;
   struct ifreq ifreq;
   int idx = 0, s, ret;

   assert(getifaddrs(&ifap) == 0);

   s = socket(AF_INET, SOCK_RAW, htons(ETHERTYPE_ARP));
   assert(s != -1);

   for(iftmp = ifap; iftmp; iftmp = iftmp->ifa_next)
     {
        if(idx > IMAXSIZE)
          {
             fprintf(stderr,
                     "maximun number of interfaces reached: %d\n", IMAXSIZE);
             break;
          }

        if(iftmp->ifa_addr->sa_family != AF_INET)
          continue;

        if(!strcmp(iftmp->ifa_name, "lo"))
          continue;

        sa = (struct sockaddr_in *)iftmp->ifa_addr;
        bc = (struct sockaddr_in *)iftmp->ifa_broadaddr;


        if(iftmp->ifa_flags & IFF_BROADCAST)
          {
             retop = inet_ntop(AF_INET, (void*)&bc->sin_addr, 
                               inet[idx].brodaddr, sizeof(inet[idx].brodaddr));
             assert(retop != NULL);
          }
        else if(iftmp->ifa_flags & IFF_POINTOPOINT)
          {
             retop = inet_ntop(AF_INET, (void*)&bc->sin_addr, 
                               inet[idx].dstaddr, sizeof(inet[idx].brodaddr));
             assert(retop != NULL);
          }

        retop = inet_ntop(AF_INET, (void*)&sa->sin_addr, 
                          inet[idx].ipaddr, sizeof(inet[idx].ipaddr));
        assert(retop != NULL);

        inet[idx].name = iftmp->ifa_name;

        strncpy(ifreq.ifr_name, inet[idx].name, sizeof(ifreq.ifr_name)+1);
        ret = ioctl(s, SIOCGIFHWADDR, &ifreq);
        assert(ret != -1);

        ptr = (u_char*)&ifreq.ifr_ifru.ifru_hwaddr.sa_data;
        inet[idx].hwaddr[0] = *ptr;
        inet[idx].hwaddr[1] = *(++ptr);
        inet[idx].hwaddr[2] = *(++ptr);
        inet[idx].hwaddr[3] = *(++ptr);
        inet[idx].hwaddr[4] = *(++ptr);
        inet[idx].hwaddr[5] = *(++ptr);
        inet[idx].gwipaddr = _gateway(inet[idx].name);
        assert(inet[idx].gwipaddr != NULL);
        ++idx;
     }
   close(s);
   freeifaddrs(ifap);
}

int main(int argc, char **argv)
{
   int idx = 0;
   interface_load();

   while(inet[idx].name != NULL)
     {
        fprintf(stdout, "<%s> IP: %s\n", inet[idx].name, inet[idx].ipaddr);
        fprintf(stdout, "<%s> HW Address: %02x:%02x:%02x:%02x:%02x:%02x\n", inet[idx].name, inet[idx].hwaddr[0] & 0xff,
            inet[idx].hwaddr[1] & 0xff, inet[idx].hwaddr[2] & 0xff,inet[idx].hwaddr[3] & 0xff,
            inet[idx].hwaddr[4] & 0xff, inet[idx].hwaddr[5] & 0xff);
        fprintf(stdout, "<%s> Default GW: %s\n", inet[idx].name, inet[idx].gwipaddr);
        fprintf(stdout, "<%s> Broadcast: %s\n", inet[idx].name, inet[idx].brodaddr ? inet[idx].brodaddr : "not applicable");
        fprintf(stdout, "<%s> Destination: %s\n", inet[idx].name, inet[idx].dstaddr ? inet[idx].dstaddr : "not applicable");
        ++idx;
     }

   return 0;
}
