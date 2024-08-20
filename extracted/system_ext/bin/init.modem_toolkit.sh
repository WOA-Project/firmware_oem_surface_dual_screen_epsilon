#!/system/bin/sh

PROP_LOG_PATH="persist.log.toolkit.log_path"
PROP_LOG_DIR="log.toolkit.current_log_dir"
PROP_LOG_PREFIX="persist.log.toolkit.log_prefix"
PROP_SDCARD_READY="log.toolkit.sdcard_ready"
PROP_LAST_BUGREPORT="log.toolkit.last_bugreport"
PROP_BUILD_TYPE="ro.product.build.type"

DEFAULT_LOG_PATH="/data/misc/logtoolkit/system_logs"
COMPRESSED_LOG_PATH="/data/misc/logtoolkit_compressed"

PROP_STATUS_ANDROID_LOGCATD="persist.log.toolkit.logcat_enable"
PROP_STATUS_DIAG_MDLOGD="persist.log.toolkit.diag_log_enable"
PROP_STATUS_ANDROID_TCPDUMPD="persist.log.toolkit.tcpdump_enable"

PROP_VALUE_LENGTH_LIMIT=91

toMakeLogRoot=
toMakeDir=
toChmod=
toRemoveLog=
toBugReport=

function print_usage() {
    print_log "$0:"
    print_log "    --mkdir        to make new log directory named by the current time"
    print_log "    --chmod        to allow all files to be readable by system"
    print_log "    --clean        to clean all log files"
    print_log "    --bugreport    to generate a bugreport.zip"
}

function print_log {
    log -t "ModemToolkit" "$@"
    echo "$@"
}

print_log "$0 $1 $2 $3 $4"
# Loop until all parameters are used up
while (( "$#" )); do
    case "$1" in
        --mkLogRoot)
            toMakeLogRoot=true
            shift
            ;;
        --mkdir)
            toMakeDir=true
            shift
            ;;
        --chmod)
            toChmod=true
            shift
            ;;
        --clean)
            toRemoveLog=true
            shift
            ;;
        --bugreport)
            toBugReport=true
            shift
            ;;
        *)
            print_usage
            exit
            ;;
    esac
done


LogRoot=`getprop $PROP_LOG_PATH`
[ "$LogRoot" == "" ] && LogRoot=$DEFAULT_LOG_PATH
if [[ $toMakeLogRoot ]]; then
    if [[ -d $LogRoot ]]; then
        print_log "$LogRoot already exists"
        setprop $PROP_SDCARD_READY logroot_ready
    else
        print_log "`mkdir -m 2770 -v -p $LogRoot/$DirName 2>&1`"
        if [[ -d $LogRoot ]]; then
            setprop $PROP_SDCARD_READY logroot_ready
        else
            exit 2 #ENOENT: No such file or directory
        fi
    fi

    exit
fi

if [[ $toMakeDir ]]; then
    DirNamePrefix=`getprop $PROP_LOG_PREFIX`
    if [ ! -z "$DirNamePrefix" ]; then
        DirNamePrefix="${DirNamePrefix}_"
    fi

    DirName=`getprop $PROP_LOG_DIR`
    if [[ "$DirName" == "" ]]; then
        DirName=`date -u +%Y%m%d-%H%M%S.%s`
        DirName=$DirNamePrefix$DirName
        setprop $PROP_LOG_DIR $DirName
    else
        OldTime="`echo $DirName | sed 's|^.*\.||'`"
        NowTime="`date +%s`"

        TimeDiff=`expr $NowTime - $OldTime`
        print_log "Now $NowTime, Old $OldTime, Diff $TimeDiff"
        if [[ "$TimeDiff" == "" ||  $TimeDiff -lt 0 || $TimeDiff -ge 5 ]]; then
            DirName=`date -u +%Y%m%d-%H%M%S.%s`
            DirName=$DirNamePrefix$DirName
            setprop $PROP_LOG_DIR $DirName
        fi
    fi

    if [[ -d $LogRoot/$DirName ]]; then
        print_log "$LogRoot/$DirName already exists"
    else
        print_log "`mkdir -m 2770 -v -p $LogRoot/$DirName 2>&1`"
    fi
fi

if [[ $toRemoveLog ]]; then
    [ `getprop $PROP_STATUS_ANDROID_LOGCATD` == "true" ] && print_log "$PROP_STATUS_ANDROID_LOGCATD is running" && exit
    [ `getprop $PROP_STATUS_DIAG_MDLOGD` == "true" ] && print_log "$PROP_STATUS_DIAG_MDLOGD is running" && exit
    [ `getprop $PROP_STATUS_ANDROID_TCPDUMPD` == "true" ] && print_log "$PROP_STATUS_ANDROID_TCPDUMPD is running" && exit
    
    if [ -d $LogRoot ]; then
        print_log "`rm -rf $LogRoot 2>&1`"
        print_log "$LogRoot was removed"
    else
        print_log "$LogRoot doesn't exist"
    fi

    if [ -d $COMPRESSED_LOG_PATH ]; then
        print_log "`rm -rf $COMPRESSED_LOG_PATH/* 2>&1`"
        print_log "$COMPRESSED_LOG_PATH was removed"
    else
        print_log "$COMPRESSED_LOG_PATH doesn't exist"
    fi
fi

if [[ $toBugReport ]]; then
    build_type=`getprop $PROP_BUILD_TYPE`
    bugreportz -p 2>&1 | while read progress; do
        print_log "$progress"
        finished=`echo $progress | grep "^OK:.*\.zip$"`

        if [ ! -z $finished ]; then
            BugReportPath=`echo $finished | cut -d ':' -f 2`

            if [ "$build_type" == "userdebug" ]; then
                if [ ! -d $LogRoot/bugreports ]; then
                    print_log "`mkdir -m 2770 -v -p $LogRoot/bugreports 2>&1`"
                fi

                FileNamePrefix=`getprop $PROP_LOG_PREFIX`
                if [ ! -z "$FileNamePrefix" ]; then
                    FileNamePrefix="${FileNamePrefix}_"
                fi
                FileName=`basename $BugReportPath`
                FileNameCp=$FileNamePrefix$FileName
                print_log "Copy bugreport to $LogRoot/bugreports/$FileNameCp"
                print_log "`cp -v $BugReportPath $LogRoot/bugreports/$FileNameCp 2>&1`"

                if [ ${#FileNameCp} -gt $PROP_VALUE_LENGTH_LIMIT ]; then
                    # If the name is too long, set it with the first $PROP_VALUE_LENGTH_LIMIT chars
                    FileNameCp=${FileNameCp:0:$PROP_VALUE_LENGTH_LIMIT}
                fi
                print_log "`setprop $PROP_LAST_BUGREPORT $FileNameCp`"
            else
                print_log "bugreport is saved to $BugReportPath"

                FileName=$BugReportPath
                if [ ${#FileName} -gt $PROP_VALUE_LENGTH_LIMIT ]; then
                    # If full path is too long, set the path in the symbolic dir /bugreports
                    BaseName=`basename $BugReportPath`
                    FileName="/bugreports/$BaseName"

                    if [ ! -f $FileName -o ${#FileName} -gt $PROP_VALUE_LENGTH_LIMIT ]; then
                        # If the path is file not found in /bugreports or the name is still too long
                        # Set the basename only
                        FileName=$BaseName

                        if [ ${#FileName} -gt $PROP_VALUE_LENGTH_LIMIT ]; then
                            # If the name is still too long, set it with the first $PROP_VALUE_LENGTH_LIMIT chars
                            FileName=${FileName:0:$PROP_VALUE_LENGTH_LIMIT}
                        fi
                    fi
                fi
                print_log "`setprop $PROP_LAST_BUGREPORT $FileName`"
            fi
        fi
    done;
fi

if [[ $toChmod ]]; then
    print_log "`find $LogRoot -type d -exec chmod g+x {} + 2>&1`"
    print_log "`chmod -R g+r $LogRoot 2>&1`"
fi
