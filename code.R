library("rvest")
library("httr")
library('wordcloud2')
library("KoNLP")
library("lawstat")
library("ggmap")
library("ggplot2")

#워드클라우드

r<-c()
w<-c()
for(i in seq(1,700,10)){
  a<-paste0("https://search.naver.com/search.naver?ie=utf8&where=news&query=피서철%20요금&sm=tab_pge&sort=0&photo=0&field=0&reporter_article=&pd=0&ds=&de=&docid=&nso=so:r,p:all,a:all&mynews=0&cluster_rank=23&start=",i) #크롤링 사이트
  r<-rbind(r,a) #크롤링 사이트 모음 (페이지 넘김)
  q<-html_text(html_nodes(read_html(GET(a)),"a._sp_each_title")) #a테그의 sp_each_Title , 제목 추출
  w<-c(w,q) #단어 모으기
} 
data=sapply(w,extractNoun,USE.NAMES=F) #명사추출
undata=unlist(data) #list안 데이터를 char로 바꿔줌
data=Filter(function(x){nchar(x)>=2},undata) #글자수가 2글자 이상
data=gsub("휴가철","",data) #휴가철 데이터 제거 : 검색어라서 제거
data=gsub("휴가","",data) #휴가 데이터 제거 : 검색어 제거

dtable<-as.data.frame(table(data)) 
dtable<-dtable[order(dtable$Freq,decreasing=T),]
wordcount<-table(dtable)
wordcloud2(dtable[dtable$Freq>1,],size=3.2,figPath="car2.jpg",color="skyblue",backgroundColor="black")
wordcloud2(dtable[dtable$Freq>1,], figPath = "car2.jpg", size = 3, color = "skyblue", backgroundColor="black")

#T-test
data21=read.csv('data11.csv', header=T)
data22=read.csv('data12.csv', header=T)

#Data 병합
q=as.data.frame(merge(data21,data22,all=T)) #병합된 데이터

#성수기 1,2,7,8월을 성수기로 지정
one = q[q$month==1,] #1월 + NA값
two = q[q$month==2,] #2월 + NA값
seven = q[q$month==7,] #7월 + NA값
eight = q[q$month==8,] #8월 + NA값

#성수기 월별 NA값 제거
one <- one[!is.na(one$month),]
two <- two[!is.na(two$month),]
seven <- seven[!is.na(seven$month),]
eight <- eight[!is.na(eight$month),]


#성수기 전체 Data
peak=rbind(one,two,seven,eight)
peak_price=peak[,56:73]

#성수기 숙박일이 1인 데이터만 추출
peak1 = peak[peak$q2_c_2 ==1 , ] #여행일이 1일인 데이터
peak1 <- peak1[!is.na(peak1$q11_a_1_1),] #지출경비 데이터
peak1 <- peak1[!(peak1$q11_a_1_1 == 0), ] #0값 제거

#비수기 3,4,10,11월 비수기로 지정
three = q[q$month==3,] #3월 + NA값
four = q[q$month==4,] #4월 + NA값
ten = q[q$month==10,] #10월 + NA값
eleven = q[q$month==11,] #11월 + NA값

#비수기 월별 NA값 제거

three <- three[!is.na(three$month),]
four <- four[!is.na(four$month),]
ten <- ten[!is.na(ten$month),]
eleven <- eleven[!is.na(eleven$month),]



#비수기 전체 Data
nonpeak=rbind(three, four, ten, eleven)
nonpeak_price=nonpeak[,56:73]

#비수기 숙박일이 1인 데이터만 추출
nonpeak1 = nonpeak[nonpeak$q2_c_2 ==1 , ]
nonpeak1 <- nonpeak1[!is.na(nonpeak1$q11_a_1_1),]
nonpeak1 <- nonpeak1[!(nonpeak1$q11_a_1_1 == 0), ]
#성수기, 비수기의 국내 관광객 (q6_1코드가 900보다 크면 국내 관광객)
in_nonpeak = nonpeak1[nonpeak1$q6_1>900,]
in_peak = peak1[peak1$q6_1>900,]

#T-test 성수기와 비수기 여행 준비 지출 차이
var.test(in_peak$q11_a_1_1, in_nonpeak$q11_a_1_1) #등분산
t.test(in_peak$q11_a_1_1, in_nonpeak$q11_a_1_1,var.equal = TRUE)
#x-square

#빈도분석
inkorea=q[q$q6_1>900,]
inkorea$q6_1<-as.factor(inkorea$q6_1)
inkorea<-inkorea[complete.cases(inkorea$q12_11),]
inkorea<-inkorea[!(inkorea$q12_11==9),]
i1<-data.frame(inkorea$q6_1,inkorea$q12_11,inkorea$q6_1_1)
gyeonggi=i1[inkorea$q6_1=="931",]
gyeonggi$inkorea.q6_1_1<-as.factor(gyeonggi$inkorea.q6_1_1)
agg_g<-aggregate(gyeonggi$inkorea.q12_11,by=list(gyeonggi$inkorea.q6_1_1),FUN=mean,na.rm=T)
ggplot(agg_g,aes(Group.1,x))+geom_point()


#Clustering
q16=as.data.frame(merge(data21,data22,all=T)) #병합된 데이터

gyeonggi<-q16[q16$q6_1==931,]
gyeonggi[gyeonggi=="9"]<-NA #설문응답 9 = 결측값
gyeonggi<-gyeonggi[complete.cases(gyeonggi$q6_1_1),] 
gyeonggi$q6_1_1<-as.factor(gyeonggi$q6_1_1)

#각 항목별 평균값
q1<-aggregate(q12_1~q6_1_1,gyeonggi,mean) #자연경관
q2<-aggregate(q12_2~q6_1_1,gyeonggi,mean) #문화유산
q3<-aggregate(q12_3~q6_1_1,gyeonggi,mean) #교통
q4<-aggregate(q12_4~q6_1_1,gyeonggi,mean) #숙박시설
q5<-aggregate(q12_5~q6_1_1,gyeonggi,mean) #식당 및 음식
q6<-aggregate(q12_6~q6_1_1,gyeonggi,mean) #쇼핑
q7<-aggregate(q12_7~q6_1_1,gyeonggi,mean) #관광정보 및 안내시설
q8<-aggregate(q12_8~q6_1_1,gyeonggi,mean) #관광지 편의시설
q9<-aggregate(q12_9~q6_1_1,gyeonggi,mean) #지역 관광종사자의 친절성
q10<-aggregate(q12_10~q6_1_1,gyeonggi,mean) #체험프로그램
q11<-aggregate(q12_11~q6_1_1,gyeonggi,mean) #관광지 물가
q12<-aggregate(q12_12~q6_1_1,gyeonggi,mean) #관광지 혼잡도

a=as.data.frame(table(gyeonggi$q6_1_1)) #지역별 설문 응답자 수

agg<-cbind(a$Freq,q1$q12_1,q2$q12_2,q3$q12_3,q4$q12_4,q5$q12_5,q6$q12_6,q7$q12_7,
           q8$q12_8,q9$q12_9,q10$q12_10,q11$q12_11,q12$q12_12)



agg.s <- agg
agg.s[,1] <-scale(a$Freq)[,1]
agg.s[,2] <- scale(agg[,2])
agg.s[,3] <- scale(agg[,3])
agg.s[,4] <- scale(agg[,4])
agg.s[,5] <- scale(agg[,5])
agg.s[,6] <- scale(agg[,6])
agg.s[,7] <- scale(agg[,7])
agg.s[,8] <- scale(agg[,8])
agg.s[,9] <- scale(agg[,9])
agg.s[,10] <- scale(agg[,10])
agg.s[,11] <- scale(agg[,11])
agg.s[,12] <- scale(agg[,12])
agg.s[,13] <- scale(agg[,13])


rownames(agg.s) <-c("수원시","성남시","의정부시","안양시","부천시","광명시","평택시","안산시","고양시","과천시","구리시","남양주시","오산시","시흥시","군포시","의왕시","하남시","용인시","파주시","이천시","안성시","김포시","화성시","광주시","양주시","포천시","여주군","연천군","가평군","양평군")
colnames(agg.s) <-c("Freq","q1","q2","q3","q4","q5","q6","q7","q8","q9","q10","q11","q12")



# Ward Hierarchical Clustering
d <- dist(agg.s, method = "euclidean")
fit <- hclust(d, method="ward.D") 
plot(fit) # display dendogram
groups <- cutree(fit, k=3) # cut tree into 4 clusters
rect.hclust(fit, k=3, border="red") 


#착한 가격 지도
good = read.csv("착한가격업소.csv", header = T)
good$주소<-as.character(good$주소)
good1 <- good[grep("경기도 수원시", good$주소),]
good2 <- good[grep("경기도 구리시", good$주소),]

gc<-geocode(enc2utf8(good$주소))
gc1<-geocode(enc2utf8(good1$주소))
gc2<-geocode(enc2utf8(good2$주소))


final<-cbind(good, gc)
final = final[!is.na(final$lon),]
final1<-cbind(good1, gc1)
final1 = final1[!is.na(final1$lon),]
final2<-cbind(good2, gc2)
final2 = final2[!is.na(final2$lon),]


#경기도 map
df<-data.frame(name=final$업소명,lon=final$lon,lat=final$lat)
cen<-c(mean(df$lon),mean(df$lat))
map<-get_googlemap(center=c(127.0383,37.50795),maptype="roadmap",zoom=9)
gmap<-ggmap(map)+geom_point(aes(x=df$lon,y=df$lat
),size=1,color="red",
data=df)
gmap

#수원시 map
df1<-data.frame(name=final1$업소명,lon=final1$lon,lat=final1$lat)
cen<-c(mean(df1$lon),mean(df1$lat))
map<-get_googlemap(center=cen,maptype="roadmap",zoom=12)
gmap<-ggmap(map)+geom_point(aes(x=df1$lon,y=df1$lat
),size=3,color="#00cefe",
data=df1)
gmap

#구리시 map
df2<-data.frame(name=final2$업소명,lon=final2$lon,lat=final2$lat)
cen<-c(mean(df2$lon),mean(df2$lat))
map<-get_googlemap(center=cen,maptype="roadmap",zoom=12)
gmap<-ggmap(map)+geom_point(aes(x=df2$lon,y=df2$lat
),size=3,color="#00cefe",
data=df2)
gmap

