#!/bin/sh

set -x

sleep 20s

ls /dev/vid* > /var/www/html/list

DATE=`date +%s`

SOURCE="/dev/video0"
RES="640x480"
FRAME="18"
FORMAT="jpeg -j 75"
LENGTH="5:00"
OUTDIR="/var/www/html/videos/$DATE/"
BASENAME="seg_${DATE}_"
SEGMENT=0
EXT=".avi"
CONVEXT=".mp4"

if [ -e /dev/video0 ];
then

	GETUSE=`df -h | grep "ubi0" | awk '{printf $5}'`
	while [ "$GETUSE" -gt 75 ]
	do
		rm -rf /var/www/html/videos/`ls -t /var/www/html/videos/| tail -1`
		GETUSE=`df -h | grep "ubi0" | awk '{printf $5}'`
	done


	mkdir ${OUTDIR}

	BATTSTATE=`battery.sh | grep "Battery charge"`

	while [ "${BATTSTATE}" == "Battery charge current = 0mA" ]
	do
  		PRINTSEG=`printf "%03d" ${SEGMENT}`
  		streamer -c ${SOURCE} -s ${RES} -r ${FRAME} -f ${FORMAT} -t ${LENGTH}\
 -o ${OUTDIR}${BASENAME}${PRINTSEG}${EXT}
  		SEGMENT=$((SEGMENT+1))
  		sync
		BATTSTATE=`battery.sh | grep "Battery charge"`
	done

	echo "${DATE}" > ${OUTDIR}DATE
	echo "${SEGMENT}" > ${OUTDIR}SEGMENTS
	echo "$(du -sh ${OUTDIR} | awk '{print $1}')" > ${OUTDIR}/SIZE
	echo "$(($SEGMENT * 5))" > ${OUTDIR}LENGTH

	cat /var/www/html/head > /var/www/html/index.html

	for D in `find /var/www/html/videos -mindepth 1 -type d | tac`
	do
		echo "$(du -sh ${D} | awk '{print $1}')" > ${D}/SIZE
		
		echo "" >> /var/www/html/index.html
		echo "					<div class=\"row\">" >> /var/www/html/index.html
		echo "						<div class=\"col-lg-12\">" >> /var/www/html/index.html
		echo "							<div class=\"bs-component\">" >> /var/www/html/index.html
		echo "								<div class=\"panel panel-primary\">" >> /var/www/html/index.html
		echo "									<div class=\"panel-heading\">" >> /var/www/html/index.html
		echo "										<h3 class=\"panel-title\"> `cat ${D}/DATE`</h3>" >> /var/www/html/index.html
		echo "									</div>" >> /var/www/html/index.html
		echo "									<div class=\"panel-body\">" >> /var/www/html/index.html
		echo "										<div class=\"row\">" >> /var/www/html/index.html
		echo "											<div class=\"col-lg-12\">" >> /var/www/html/index.html
		echo "												<div class=\"bs-component\" style=\"margin-bottom: 15px;\">" >> /var/www/html/index.html
		echo "													<p class=\"lead\">Segment[s]: `cat ${D}/SEGMENTS`<br>" >> /var/www/html/index.html
		echo "													Length: `cat ${D}/LENGTH` min.<br>" >> /var/www/html/index.html
		echo "													Size: `cat ${D}/SIZE`</p>" >> /var/www/html/index.html


		for i in $(seq 1 `cat ${D}/SEGMENTS`)
		do
			FILESUB=$((i-1))
			echo "														\
<a href=\"videos/`cat ${D}/DATE`\
/seg_`cat ${D}/DATE`_`printf "%03d" ${FILESUB}`${CONVEXT}\
\" class=\"btn btn-default btn-lg btn-block\">0x\
`printf "%03d" ${FILESUB}`\
</a>" >> /var/www/html/index.html
		done

		echo "												</div>" >> /var/www/html/index.html
		echo "											</div>" >> /var/www/html/index.html
		echo "										</div>" >> /var/www/html/index.html
		echo "									</div>" >> /var/www/html/index.html
		echo "								</div>" >> /var/www/html/index.html
		echo "							</div>" >> /var/www/html/index.html
		echo "						</div>" >> /var/www/html/index.html
		echo "					</div>" >> /var/www/html/index.html
		echo "" >> /var/www/html/index.html
	done

	cat /var/www/html/tail >> /var/www/html/index.html

	for i in $(seq 1 ${SEGMENT})
	do
		FILESUB=$((i-1))
		PRINTSEG=`printf "%03d" $FILESUB`
		ffmpeg -i ${OUTDIR}${BASENAME}${PRINTSEG}${EXT} ${OUTDIR}${BASENAME}${PRINTSEG}${CONVEXT}
		rm ${OUTDIR}${BASENAME}${PRINTSEG}${EXT}
	done

fi

BATTSTATE=`battery.sh | grep "Battery charge"`

while [ "${BATTSTATE}" == "Battery charge current = 0mA" ]
do
	echo "waiting"
	BATTSTATE=`battery.sh | grep "Battery charge"`
	sleep 10s
done

sync

poweroff

exit 0
