#!/bin/bash
#依赖的工具: wget, grep, sed, awk

Usage()
{
    echo "只需要1个URL,格式可如下:"
    echo -e "$0 http://www.maiziedu.com/course/9/       \033[31;35m某课程列表页面\033[0m"
    echo -e "$0 http://www.maiziedu.com/course/9-52/    \033[31;35m某课程播放页面\033[0m"
    echo -e "$0 http://www.maiziedu.com/course/android/ \033[31;35m某职业学习路线\033[0m"
    echo -e "$0 http://www.maiziedu.com/                \033[31;35m下载全站视频，并分类保存\033[0m"
}

Download()
{
    CourseURL=$1 #like this:http://www.maiziedu.com/course/9/
    MajorName=$2
    MajorSeq=$3
    ClassID=`echo $CourseURL | awk -F \/ '{print $5}'`
    WgetFile=/tmp/tmp_`date +'%N'`
    DutyList=/tmp/tmp_`date +'%N'`
    wget $CourseURL -O $WgetFile  --user-agent='Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Maxthon/4.9.5.1000 Chrome/39.0.2146.0 Safari/537.36'
    CourseName=`cat $WgetFile  | grep '<h1 class=' | awk -F \> '{print $2}'| awk -F \< '{print $1}' | sed 's/[ ][ ]*//g'|sed 's/\t//g' `
    if [ ! -z $MajorSeq ]
    then
        CourseName=$MajorSeq-$CourseName
        echo -e "\033[42;44m正在下载[$MajorName]->[$CourseName]->[$CourseURL]\033[0m"
    else
        echo -e "\033[42;44m正在下载[$CourseName]->[$CourseURL]\033[0m"
    fi
    cat $WgetFile|grep "<li><a href=\"/course/$ClassID"|awk -F \" '{print $2"@"$9}'|sed -r s/\(\>\|\<.*\)//g|sed s/$/.mp4/g|sed 's/[ ][ ]*//g'|sed 's/\t//g' >$DutyList
    mkdir $CourseName 2>&1 | > /dev/null
    FileSeq=0;
    for line in `cat $DutyList`
    do
        let FileSeq+=1
        url='http://www.maiziedu.com'`echo $line | awk -F @ '{print $1}'`

        if [ $FileSeq -le 9 ]
        then
            filename=0`echo $line | awk -F @ '{print $2}' `
        else
            filename=`echo $line | awk -F @ '{print $2}' `
        fi

        LoopTmpFile=/tmp/tmp_`date +'%N'`
        wget $url -O $LoopTmpFile  --user-agent='Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Maxthon/4.9.5.1000 Chrome/39.0.2146.0 Safari/537.36'
        realsource=`cat $LoopTmpFile | grep lessonUrl 2>&1 | awk -F \" '{print $2}'`
        echo -e "\033[32;38m正在从[$realsource]下载[$filename],保存到[$CourseName]目录.\033[0m"
        wget -c -T 10 $realsource -O $CourseName/$filename --user-agent='Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Maxthon/4.9.5.1000 Chrome/39.0.2146.0 Safari/537.36'
    done
    rm -rf $WgetFile
    rm -rf $DutyList
}

DownloadMajor()
{
    CourseURL=$1
    WgetFileMajor=/tmp/tmp_`date +'%N'`
    wget  $CourseURL -O $WgetFileMajor --user-agent='Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Maxthon/4.9.5.1000 Chrome/39.0.2146.0 Safari/537.36'
    MajorName=`cat $WgetFileMajor | grep -A 4 '<li><a href="/course/">'| grep active|awk -F \> '{print $2}'|awk -F \< '{print $1}'|sed 's/[ ][ ]*/_/g'|sed 's/\t//g'`
    mkdir $MajorName > /dev/null 2>&1
    cd $MajorName
    wget  $CourseURL -O $WgetFileMajor --user-agent='Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Maxthon/4.9.5.1000 Chrome/39.0.2146.0 Safari/537.36'
    DownloadMajorSeq=1
    for line in `cat $WgetFileMajor | grep '<a href="/course/'| grep -v '</a>'| awk -F \" '{print "http://www.maiziedu.com"$2}'`
    do
        Download $line $MajorName `printf "%02d\n" $DownloadMajorSeq`
        let DownloadMajorSeq+=1
    done
    rm -rf $WgetFileMajor
}

DownloadMajorAll()
{
    CourseURL=$1
    DownloadMajorAllFile=/tmp/tmp_`date +'%N'`
    wget  $CourseURL -O $DownloadMajorAllFile --user-agent='Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Maxthon/4.9.5.1000 Chrome/39.0.2146.0 Safari/537.36'
    for line in `cat $DownloadMajorAllFile | grep '<h1 class="font12 tea-tit">' -B 5 | grep '<a href="/course/' |awk -F \" '{print "http://www.maiziedu.com"$2}'`
    do
        cd $pwd
        DownloadMajor $line
    done
}

###############  main   ####################################
if [ $# -ne 1 ]
then
    Usage
    exit
fi

echo $1 | grep 'http://www.maiziedu.com/' >>/dev/null 2>&1
if [ 0 -ne $? ]
then
    echo "URL 格式不对"
    Usage
    exit
fi

rm -rf /tmp/tmp*
CourseURL=$1
pwd=$PWD


echo $CourseURL | awk -F \/ '{print $5}' | grep -P '^\d+$' >/dev/null 2>&1 #纯数字
if [ 0 -eq $? ]
then
    echo -e "\033[45;39m进入模式1，下载某课程列表所有视频\033[0m"
    Download $CourseURL
    exit
fi

echo $CourseURL | awk -F \/ '{print $5}' | grep -P '^\d' >/dev/null 2>&1 #数字开头
if [  0 -eq $? ]
then
    echo -e "\033[45;39m进入模式2，下载某课程列表所有视频\033[0m"
    Download `echo $CourseURL|  awk -F \- '{print $1"/"}'`
    exit
fi

echo $CourseURL | awk -F \/ '{print $5}' | grep -P '^[a-zA-Z]+$' >/dev/null 2>&1 #字母开头
if [  0 -eq $? ]
then
    echo -e "\033[45;39m进入模式3，下载某职业所有课程视频\033[0m"
    DownloadMajor $CourseURL
    exit
fi

echo -e "\033[45;39m进入模式4，下载全站课程视频\033[0m" #下载全站
DownloadMajorAll $CourseURL

