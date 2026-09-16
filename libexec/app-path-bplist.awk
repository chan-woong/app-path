BEGIN{n=0}{for(i=1;i<=NF;i++)b[n++]=$i}END{
if(n<40)exit 2;if(b[0]!=98||b[1]!=112||b[2]!=108||b[3]!=105||b[4]!=115||b[5]!=116||b[6]!=48||b[7]!=48)exit 3
t=n-32;os=b[t+6];rs=b[t+7];num=U(t+8,8);top=U(t+16,8);tab=U(t+24,8);if(os<1||rs<1||num<1)exit 4
for(i=0;i<num;i++)off[i]=U(tab+i*os,os)
for(i=0;i<num;i++){p=off[i];m=b[p];ty=int(m/16);inf=m%16;ot[i]=ty;oi[i]=inf
if(ty==5||ty==6){LEN(p,inf);ol[i]=L;oh[i]=H;s="";if(ty==5)for(j=0;j<ol[i];j++)s=s CH(b[p+oh[i]+j]);else for(j=0;j<ol[i];j++)s=s U16(b[p+oh[i]+2*j],b[p+oh[i]+2*j+1]);str[i]=s}
else if(ty==10){LEN(p,inf);ol[i]=L;oh[i]=H;base=p+oh[i];for(j=0;j<ol[i];j++)ar[i,j]=U(base+j*rs,rs)}
else if(ty==13){LEN(p,inf);ol[i]=L;oh[i]=H;base=p+oh[i];for(j=0;j<ol[i];j++){dk[i,j]=U(base+j*rs,rs);dv[i,j]=U(base+ol[i]*rs+j*rs,rs)}}}
if(verify!=""){print(TOP(top,"CFBundleIdentifier")==verify?"MATCH":"NO_MATCH");exit}
if(topquery!=""){print topquery "\t" TOP(top,topquery);exit}
if(list=="1"){name=TOP(top,"CFBundleDisplayName");if(name=="")name=TOP(top,"CFBundleName");print TOP(top,"CFBundleIdentifier")"\t"name"\t"TOP(top,"CFBundleExecutable")"\t"TOP(top,"CFBundleShortVersionString")"\t"TOP(top,"CFBundleVersion");exit}
if(schemes=="1"){FSCH(top,0);exit}if(query!=""){FIND(top,query,0);exit}}
function U(p,c,v,i){v=0;for(i=0;i<c;i++)v=v*256+b[p+i];return v}
function LEN(p,x,m,z){if(x<15){L=x;H=1;return}m=b[p+1];if(int(m/16)!=1){L=0;H=0;return}z=2^(m%16);L=U(p+2,z);H=2+z}
function CH(x){return(x>=32&&x<=126)?sprintf("%c",x):"?"}
function U16(h,l){if(h==0&&l>=32&&l<=126)return sprintf("%c",l);if(h==0&&l==9)return "\t";return "?"}
function VAL(v,i,s){if(ot[v]==5||ot[v]==6)return str[v];if(ot[v]==0){if(oi[v]==8)return"false";if(oi[v]==9)return"true";return"null"}if(ot[v]==1)return U(off[v]+1,2^oi[v]);if(ot[v]==10){s="";for(i=0;i<ol[v];i++){if(s!="")s=s"\n";s=s VAL(ar[v,i])}return s}return"<complex>"}
function TOP(o,k,i){if(ot[o]!=13)return"";for(i=0;i<ol[o];i++)if(VAL(dk[o,i])==k)return VAL(dv[o,i]);return""}
function FIND(o,k,d,i,n,v){if(d>64)return;if((k SUBSEP o)in seen)return;seen[k SUBSEP o]=1;if(ot[o]==13)for(i=0;i<ol[o];i++){n=VAL(dk[o,i]);v=dv[o,i];if(n==k)EMIT(v,k);if(ot[v]==13||ot[v]==10)FIND(v,k,d+1)}else if(ot[o]==10)for(i=0;i<ol[o];i++){v=ar[o,i];if(ot[v]==13||ot[v]==10)FIND(v,k,d+1)}}
function EMIT(v,k,i){if(ot[v]==10)for(i=0;i<ol[v];i++)print k"\t"VAL(ar[v,i]);else print k"\t"VAL(v)}
function FSCH(o,d,i,k,v,j){if(d>64)return;if((o SUBSEP"S")in ss)return;ss[o SUBSEP"S"]=1;if(ot[o]==13)for(i=0;i<ol[o];i++){k=VAL(dk[o,i]);v=dv[o,i];if(k=="CFBundleURLSchemes"&&ot[v]==10)for(j=0;j<ol[v];j++)print "CFBundleURLSchemes\t"VAL(ar[v,j]);if(ot[v]==13||ot[v]==10)FSCH(v,d+1)}else if(ot[o]==10)for(i=0;i<ol[o];i++){v=ar[o,i];if(ot[v]==13||ot[v]==10)FSCH(v,d+1)}}
