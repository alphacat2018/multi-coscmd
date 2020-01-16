#!/bin/bash

COLOR_RED=`tput setaf 1`
COLOR_GREEN=`tput setaf 2`
COLOR_YELLOW=`tput setaf 3`
COLOR_RESET=`tput sgr0`

COMPLETE_COS_CONFIG_PATH=~/.cos.conf.all
TEMP_COS_CONFIG_PATH=~/.cos.conf.tmp
USER_COS_CONFIG_PATH=~/.cos.conf
COSCMD_ORIGINAL_FILE_PATH=$(which coscmd)
COSCMD_ORIGINAL_FILE_FOLDER_PATH=${COSCMD_ORIGINAL_FILE_PATH%/*}
COSCMD_ORIGINAL_FILE_NEW_PATH="$COSCMD_ORIGINAL_FILE_FOLDER_PATH/__coscmd"


if [[ $@ == "-a" ]]; then           # 打印所有配置
    cat $COMPLETE_COS_CONFIG_PATH
elif [[ $@ == "reset" ]]; then    # 还原coscmd
    sudo mv $COSCMD_ORIGINAL_FILE_NEW_PATH $COSCMD_ORIGINAL_FILE_PATH
else
    if [[ $@ =~ "-b" ]]; then
        bucket=$(echo $@ | sed -E 's/.*(^| )-b ([a-z0-9\-]+).*/\2/')

        # 在进行coscmd config的操作
        if [[ $@ =~ (^| )config( ).*$ ]]; then
            # 首先执行本来的操作
            __coscmd $@

            if [[ ! $(cat "$COMPLETE_COS_CONFIG_PATH") =~ "$bucket" ]]; then
                echo '' >> "$COMPLETE_COS_CONFIG_PATH"
                cat "$USER_COS_CONFIG_PATH" >> "$COMPLETE_COS_CONFIG_PATH"
                echo "${COLOR_GREEN}[${bucket}]的配置已添加到${COMPLETE_COS_CONFIG_PATH}${COLOR_RESET}"
            else
                cat $COMPLETE_COS_CONFIG_PATH | tr '\n' '\t' | sed -E 's/^(.*)\[[^\[]+'$bucket'[^\[]+(.*)$/\1\2/' | tr '\t' '\n' | xargs -I {} echo {} > $TEMP_COS_CONFIG_PATH
                cat "$USER_COS_CONFIG_PATH" >> $TEMP_COS_CONFIG_PATH
                mv $TEMP_COS_CONFIG_PATH $COMPLETE_COS_CONFIG_PATH
                echo "${COLOR_GREEN}[${bucket}]的配置已更新到${COMPLETE_COS_CONFIG_PATH}${COLOR_RESET}"
            fi
            exit
        else
            if [[ $(cat "$COMPLETE_COS_CONFIG_PATH") =~ "$bucket" ]]; then
                echo "${COLOR_YELLOW}正在切换配置到[${bucket}]${COLOR_RESET}"
                cat $COMPLETE_COS_CONFIG_PATH | tr '\n' '\t' | sed -E 's/.*(\[[^\[]+'$bucket'[^\[]+).*/\1/' | tr '\t' '\n' | xargs -I {} echo {} > $USER_COS_CONFIG_PATH
            else
                echo "${COLOR_RED}${COMPLETE_COS_CONFIG_PATH}中[${bucket}]的配置不存在,将继续使用以下配置${COLOR_RESET}"
                cat $USER_COS_CONFIG_PATH
            fi
        fi
    fi

    # 将接收到的header传给__coscmd时会因为引号的问题导致报错
    header="{}"
    commandWithoutHeader="$@"

    if [[ $@ =~ "-H" ]]; then
        header=$(echo $@ | sed -E "s/(^|.* )(-H) ({[^}]*})(.*)/\3/")
        commandWithoutHeader=$(echo $@ | sed -E "s/(^|.* )(-H {[^}]*})(.*)/\1\3/")
    fi

    __coscmd $commandWithoutHeader -H "$header"
fi

