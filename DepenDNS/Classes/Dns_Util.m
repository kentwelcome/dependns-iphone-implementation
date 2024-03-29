//DNS Query Program on Linux
//Author : Prasshhant Pugalia (prasshhant.p@gmail.com)
//Dated : 29/4/2009

#include "Dns_Util.h"

//List of DNS Servers registered on the system
#define MAXNS 10
char dns_servers[MAXNS][100];

//Type field of Query and Answer
#define T_A 1 /* host address */
#define T_NS 2 /* authoritative server */
#define T_CNAME 5 /* canonical name */
#define T_SOA 6 /* start of authority zone */
#define T_PTR 12 /* domain name pointer */
#define T_MX 15 /* mail routing information */

//Function Prototypes
void ngethostbyname (unsigned char* host, unsigned char* server, NSCountedSet* answer_array);
void ChangetoDnsNameFormat (unsigned char*,unsigned char*);
unsigned char* ReadName (unsigned char*,unsigned char*,int*);

//DNS header structure
struct DNS_HEADER
{
	unsigned short id; // identification number
	
	unsigned char rd :1; // recursion desired
	unsigned char tc :1; // truncated message
	unsigned char aa :1; // authoritive answer
	unsigned char opcode :4; // purpose of message
	unsigned char qr :1; // query/response flag
	
	unsigned char rcode :4; // response code
	unsigned char cd :1; // checking disabled
	unsigned char ad :1; // authenticated data
	unsigned char z :1; // its z! reserved
	unsigned char ra :1; // recursion available
	
	unsigned short q_count; // number of question entries
	unsigned short ans_count; // number of answer entries
	unsigned short auth_count; // number of authority entries
	unsigned short add_count; // number of resource entries
};

//Constant sized fields of query structure
struct QUESTION
{
	unsigned short qtype;
	unsigned short qclass;
};

//Constant sized fields of the resource record structure
#pragma pack(push, 1)
struct R_DATA
{
	unsigned short type;
	unsigned short _class;
	unsigned int ttl;
	unsigned short data_len;
};
#pragma pack(pop)

//Pointers to resource record contents
struct RES_RECORD
{
	unsigned char *name;
	struct R_DATA *resource;
	unsigned char *rdata;
};

//Structure of a Query
typedef struct
	{
		unsigned char *name;
		struct QUESTION *ques;
	} QUERY;

/*
int main()
{
	unsigned char hostname[100];
	
	//Get the DNS servers from the resolv.conf file
	get_dns_servers();
	//Get the hostname
	printf("nEnter Hostname to Lookup : ");
	gets((char*)hostname);
	//Now get the ip of this hostname
	ngethostbyname(hostname);
	
	return 0;
}
*/

void ngethostbyname(unsigned char *host, unsigned char* dnsserver, NSCountedSet* answer_array)
{
	
	unsigned char buf[65536],*qname,*reader;
	int i , j , stop , s;
	
	struct sockaddr_in a;
	
	struct RES_RECORD answers[20],auth[20],addit[20]; //the replies from the DNS server
	struct sockaddr_in dest;
	
	struct DNS_HEADER *dns = NULL;
	struct QUESTION *qinfo = NULL;
	
	s = socket(AF_INET , SOCK_DGRAM , IPPROTO_UDP); //UDP packet for DNS queries
	
	dest.sin_family = AF_INET;
	dest.sin_port = htons(53);
	NSLog(@"dns_servers: %s", dnsserver);
	dest.sin_addr.s_addr = inet_addr((const char*)dnsserver); //dns servers
	
	//Set the DNS structure to standard queries
	dns = (struct DNS_HEADER *)&buf;
	
	dns->id = (unsigned short) htons(getpid());
	dns->qr = 0; //This is a query
	dns->opcode = 0; //This is a standard query
	dns->aa = 0; //Not Authoritative
	dns->tc = 0; //This message is not truncated
	dns->rd = 1; //Recursion Desired
	dns->ra = 0; //Recursion not available! hey we dont have it (lol)
	dns->z = 0;
	dns->ad = 0;
	dns->cd = 0;
	dns->rcode = 0;
	dns->q_count = htons(1); //we have only 1 question
	dns->ans_count = 0;
	dns->auth_count = 0;
	dns->add_count = 0;
	
	//point to the query portion
	qname =(unsigned char*)&buf[sizeof(struct DNS_HEADER)];
	
	ChangetoDnsNameFormat(qname, host);
	
	qinfo =(struct QUESTION*)&buf[sizeof(struct DNS_HEADER) + (strlen((const char*)qname) + 1)]; //fill it
	
	qinfo->qtype = htons(1); //we are requesting the ipv4 address
	qinfo->qclass = htons(1); //its internet (lol)
	
	NSLog(@"\nSending Packet...");
	if(sendto(s,(char*)buf,sizeof(struct DNS_HEADER) + (strlen((const char*)qname)+1) + sizeof(struct QUESTION),0,(struct sockaddr*)&dest,sizeof(dest)) == 0)
	{
		NSLog(@"Error sending socket");
	}
	NSLog(@"Sent");
	
	i = sizeof(dest);
	
	NSLog(@"\nReceiving answer...");
	
	/*
	 * ssize_t recvfrom(int socket, void *buffer, size_t length, int flags,
	 *	struct sockaddr *address, socklen_t *address_len);
	 */
	if(recvfrom(s, (char*)buf, 65536, 0, (struct sockaddr*)&dest, (socklen_t*)&i) == 0)
	{
		NSLog(@"Failed. Error Code ");
	}
	NSLog(@"Received.");
	
	dns = (struct DNS_HEADER*) buf;
	
	//move ahead of the dns header and the query field
	reader = &buf[sizeof(struct DNS_HEADER) + (strlen((const char*)qname)+1) + sizeof(struct QUESTION)];
	
	//NSLog(@"\n The response contains : ");
	//NSLog(@"\n %d Questions.",ntohs(dns->q_count));
	//NSLog(@"\n %d Answers.",ntohs(dns->ans_count));
	//NSLog(@"\n %d Authoritative Servers.",ntohs(dns->auth_count));
	//NSLog(@"\n %d Additional records.nn",ntohs(dns->add_count));
	
	//reading answers
	stop=0;
	
	for(i=0;i<ntohs(dns->ans_count);i++)
	{
		answers[i].name=ReadName(reader,buf,&stop);
		reader = reader + stop;
		
		answers[i].resource = (struct R_DATA*)(reader);
		reader = reader + sizeof(struct R_DATA);
		
		if(ntohs(answers[i].resource->type) == 1) //if its an ipv4 address
		{
			answers[i].rdata = (unsigned char*)malloc(ntohs(answers[i].resource->data_len));
			
			for(j=0 ; j<ntohs(answers[i].resource->data_len) ; j++)
				answers[i].rdata[j]=reader[j];
			
			answers[i].rdata[ntohs(answers[i].resource->data_len)] = '\0';
			
			reader = reader + ntohs(answers[i].resource->data_len);
		}
		else
		{
			answers[i].rdata = ReadName(reader,buf,&stop);
			reader = reader + stop;
		}
	}
	
	//read authorities
	for(i=0;i<ntohs(dns->auth_count);i++)
	{
		auth[i].name=ReadName(reader,buf,&stop);
		reader+=stop;
		
		auth[i].resource=(struct R_DATA*)(reader);
		reader+=sizeof(struct R_DATA);
		
		auth[i].rdata=ReadName(reader,buf,&stop);
		reader+=stop;
	}
	
	//read additional
	for(i=0;i<ntohs(dns->add_count);i++)
	{
		addit[i].name=ReadName(reader,buf,&stop);
		reader+=stop;
		
		addit[i].resource=(struct R_DATA*)(reader);
		reader+=sizeof(struct R_DATA);
		
		if(ntohs(addit[i].resource->type)==1)
		{
			addit[i].rdata = (unsigned char*)malloc(ntohs(addit[i].resource->data_len));
			for(j=0;j<ntohs(addit[i].resource->data_len);j++)
				addit[i].rdata[j]=reader[j];
			
			addit[i].rdata[ntohs(addit[i].resource->data_len)]= '\0'; // empty char
			reader+=ntohs(addit[i].resource->data_len);
		}
		else
		{
			addit[i].rdata=ReadName(reader,buf,&stop);
			reader+=stop;
		}
	}
	
	//print answers
	for(i=0;i<ntohs(dns->ans_count);i++)
	{
		//printf("nAnswer : %d",i+1);
		//printf("Name : %s ",answers[i].name);
		
		if(ntohs(answers[i].resource->type)==1) //IPv4 address
		{
			
			long *p;
			p=(long*)answers[i].rdata;
			a.sin_addr.s_addr=(*p); //working without ntohl
			//NSLog(@"has IPv4 address : %s", inet_ntoa(a.sin_addr));
			NSString *ipstr = [NSString stringWithFormat:@"%s", inet_ntoa(a.sin_addr)];
			[answer_array addObject:ipstr];
		}
		if(ntohs(answers[i].resource->type)==5) {
			// Canonical name for an alias
			// NSLog(@"has alias name : %s",answers[i].rdata);
		}
		NSLog(@"\n");
	}
	
	//print authorities
	for(i=0;i<ntohs(dns->auth_count);i++)
	{
		//printf("nAuthorities : %d",i+1);
		printf("Name : %s ",auth[i].name);
		if(ntohs(auth[i].resource->type)==2) {
			//printf("has authoritative nameserver : %s",auth[i].rdata);
		}
		printf("\n");
	}
	
	//print additional resource records
	for(i=0;i<ntohs(dns->add_count);i++)
	{
		//printf("nAdditional : %d",i+1);
		printf("Name : %s ",addit[i].name);
		if(ntohs(addit[i].resource->type)==1)
		{
			long *p;
			p=(long*)addit[i].rdata;
			a.sin_addr.s_addr=(*p); //working without ntohl
			//printf("has IPv4 address : %s",inet_ntoa(a.sin_addr));
		}
		printf("n");
	}
	
	return;
}

unsigned char* ReadName(unsigned char* reader,unsigned char* buffer,int* count)
{
	unsigned char *name;
	unsigned int p=0,jumped=0,offset;
	int i , j;
	
	*count = 1;
	name = (unsigned char*)malloc(256);
	
	name[0] = '\0';
	
	//read the names in 3www6google3com format
	while(*reader!=0)
	{
		if(*reader>=192)
		{
			offset = (*reader)*256 + *(reader+1) - 49152;
			reader = buffer + offset - 1;
			jumped = 1; //we have jumped to another location so counting wont go up!
		}
		else
			name[p++]=*reader;
		
		reader=reader+1;
		
		if(jumped==0)
			*count = *count + 1; //if we havent jumped to another location then we can count up
	}
	
	name[p] = 0; //string complete
	if(jumped==1)
		*count = *count + 1; //number of steps we actually moved forward in the packet
	
	//now convert 3www6google3com0 to www.google.com
	for(i=0;i<(int)strlen((const char*)name);i++) {
		p=name[i];
		for(j=0;j<(int)p;j++) {
			name[i]=name[i+1];
			i=i+1;
		}
		name[i]='.';
	}
	name[i-1] = '\0'; //remove the last dot
	return name;
}

void ChangetoDnsNameFormat(unsigned char* dns,unsigned char* host) {
	
	int lock = 0 , i;
	strcat((char*)host,".");
	
	for(i = 0 ; i < (int)strlen((char*)host) ; i++) {
		if(host[i]=='.') {
			*dns++=i-lock;
			for(;lock<i;lock++) {
				*dns++=host[lock];
			}
			lock++; //or lock=i+1;
		}
	}
	*dns++ = '\0';
}