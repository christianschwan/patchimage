#!/bin/bash

setup_tools () {

	if [[ $(uname -m) == "x86_64" ]]; then
		SUFFIX=64
	else
		SUFFIX=32
	fi

	if [[ $(which wit) ]]; then
		WIT=$(which wit)
	else
		WIT=${PATCHIMAGE_TOOLS_DIR}/wit.${SUFFIX}
	fi

	if [[ $(which applyppf3) ]]; then
		PPF=$(which applyppf3)
	else
		PPF=${PATCHIMAGE_TOOLS_DIR}/applyppf3.${SUFFIX}
	fi

	if [[ $(which uips) ]]; then
		IPS=$(which uips)
	else
		IPS=${PATCHIMAGE_TOOLS_DIR}/uips.${SUFFIX}
	fi

	if [[ $(which unp) ]]; then
		UNP=$(which unp)
	else
		UNP=${PATCHIMAGE_TOOLS_DIR}/unp
	fi

}

ask_game () {

echo -e \
"************************************************
patchimage.sh

Enter Letter for the Game you want to create:
A	NewerSMB
B	Newer Summer Sun
C	AnotherSMB
D	Newer: Holiday Special
E	Cannon Super Mario Bros.
F	Epic Super Bowser World
G	Koopa Country
H	New Super Mario Bros. 4
I	New Super Mario Bros. Wii Retro Remix
J	Super Mario: Mushroom Adventure PLUS - Winter Moon
K	NSMBW3: The Final Levels
L	Super Mario Vacation
M	Awesomer Super Luigi Mini

1	The Legend of Zelda: Parallel Worlds
"

read GAME

}

download_soundtrack () {

	if [[ ${SOUNDTRACK} ]]; then
		if [[ ${SOUNDTRACK_LINK} ]]; then
			wget --no-check-certificate "${PATCHIMAGE_AUDIO_DIR}"/"${SOUNDTRACK_LINK}" -O "${PATCHIMAGE_RIIVOLUTION_DIR}"/${SOUNDTRACK_ZIP} || exit 57
			echo -e "\n >>> soundtrack saved to\n >>> ${PATCHIMAGE_AUDIO_DIR}/${SOUNDTRACK_ZIP}"
		else
			echo -e "no soundtrack for ${GAME} available."
		fi
	fi

}

download_banner () {

	if [[ ${PATCHIMAGE_BANNER_DOWNLOAD} == "TRUE" ]]; then
		if [[ ${CUSTOM_BANNER} ]]; then
			if [[ ! -f "${PATCHIMAGE_RIIVOLUTION_DIR}"/${GAMEID}-custom-banner.bnr ]]; then
				wget --no-check-certificate "${CUSTOM_BANNER}" -O "${PATCHIMAGE_RIIVOLUTION_DIR}"/${GAMEID}-custom-banner.bnr__tmp || exit 57
				mv "${PATCHIMAGE_RIIVOLUTION_DIR}"/${GAMEID}-custom-banner.bnr__tmp "${PATCHIMAGE_RIIVOLUTION_DIR}"/${GAMEID}-custom-banner.bnr
			fi
			BANNER="${PATCHIMAGE_RIIVOLUTION_DIR}"/${GAMEID}-custom-banner.bnr
		else
			echo "*** >> no custom banner available"
		fi
	fi

}

nsmbw_version () {

	if [[ -f ${WORKDIR}/files/COPYDATE_LAST_2009-10-03_232911 ]]; then
		VERSION=EURv1
		REG_LETTER=P
	elif [[ -f ${WORKDIR}/files/COPYDATE_LAST_2010-01-05_152101 ]]; then
		VERSION=EURv2
		REG_LETTER=P
	elif [[ -f ${WORKDIR}/files/COPYDATE_LAST_2009-10-03_232303 ]]; then
		VERSION=USAv1
		REG_LETTER=E
	elif [[ -f ${WORKDIR}/files/COPYDATE_LAST_2010-01-05_143554 ]]; then
		VERSION=USAv2
		REG_LETTER=E
	elif [[ -f ${WORKDIR}/files/COPYDATE_LAST_2009-10-03_231655 ]]; then
		VERSION=JPNv1
		REG_LETTER=J
	elif [[ ! ${VERSION} ]]; then
		echo -e "please specify your games version using --version={EURv1,EURv2,USAv1,USAv2,JPNv1}"
		exit 27
	fi
	echo "*** >> status: ${VERSION}"
}

apply_banner () {

	if [[ ${BANNER} != "" ]]; then
		if [[ -e ${BANNER} ]]; then
			cp "${BANNER}" "${BANNER_LOCATION}"
		else
			echo "specified banner ${BANNER} does not exist, not modifying"
		fi
	fi

}

check_directories () {

	if [[ ! -d ${PATCHIMAGE_RIIVOLUTION_DIR} ]]; then
		mkdir -p ${PATCHIMAGE_RIIVOLUTION_DIR}
	fi

	if [[ ! -d ${PATCHIMAGE_WBFS_DIR} ]]; then
		mkdir -p ${PATCHIMAGE_WBFS_DIR}
	fi

	if [[ ! -d ${PATCHIMAGE_GAME_DIR} ]]; then
		mkdir -p ${PATCHIMAGE_GAME_DIR}
	fi

	if [[ ! -d ${PATCHIMAGE_AUDIO_DIR} ]]; then
		mkdir -p ${PATCHIMAGE_AUDIO_DIR}
	fi

}


check_input_image () {

	x=0
	if [[ ! ${IMAGE} ]]; then
		if [[ -f BASE.wbfs ]]; then
			x=1
			IMAGE=BASE.wbfs
		elif [[ -f BASE.iso ]]; then
			x=1
			IMAGE=BASE.iso
		fi
	fi
	echo "*** >> status: ${x}"

}

check_input_image_nsmb () {

	x=0
	if [[ ! ${IMAGE} ]]; then
		if test -f SMN?01.wbfs; then
			x=1
			IMAGE=SMN?01.wbfs
		elif test -f SMN?01.iso; then
			x=2
			IMAGE=SMN?01.iso
		elif test -f ${PATCHIMAGE_WBFS_DIR}/SMN?01.iso; then
			x=3
			IMAGE=${PATCHIMAGE_WBFS_DIR}/SMN?01.iso
		elif test -f ${PATCHIMAGE_WBFS_DIR}/SMN?01.wbfs; then
			x=4
			IMAGE=${PATCHIMAGE_WBFS_DIR}/SMN?01.wbfs
		else
			echo -e "please specify image to use with --iso=<path>"
			exit 15
		fi
	fi
	echo "*** >> status: ${x}"

}

check_riivolution_patch () {

	x=0
	if [[ ! -d ${RIIVOLUTION_DIR} ]]; then
		x=1
		if [[ -f "${PWD}/${RIIVOLUTION_DIR}" ]]; then
			echo "*** >> unpacking"
			x=2
			${UNP} "${PWD}/${RIIVOLUTION_ZIP}" >/dev/null || exit 63
		elif [[ -f "${PATCHIMAGE_RIIVOLUTION_DIR}/${RIIVOLUTION_ZIP}" ]]; then
			echo "*** >> unpacking"
			x=3
			${UNP} "${PATCHIMAGE_RIIVOLUTION_DIR}/${RIIVOLUTION_ZIP}" >/dev/null || exit 63
		elif [[ ${PATCHIMAGE_RIIVOLUTION_DOWNLOAD} == "TRUE" ]]; then
			x=4
			if [[ ${DOWNLOAD_LINK} ]]; then
				if [[ ! -f "${PATCHIMAGE_RIIVOLUTION_DIR}/${RIIVOLUTION_ZIP}" ]]; then
					x=5
					echo "*** >> downloading"
					wget --no-check-certificate ${DOWNLOAD_LINK} -O "${PATCHIMAGE_RIIVOLUTION_DIR}/${RIIVOLUTION_ZIP}"__tmp >/dev/null || exit 57
					mv "${PATCHIMAGE_RIIVOLUTION_DIR}/${RIIVOLUTION_ZIP}"__tmp "${PATCHIMAGE_RIIVOLUTION_DIR}/${RIIVOLUTION_ZIP}"
					echo "*** >> unpacking"
					${UNP} "${PATCHIMAGE_RIIVOLUTION_DIR}/${RIIVOLUTION_ZIP}" >/dev/null || exit 63
				fi
			else
				echo "no download link for ${GAMENAME} available."
				exit 21
			fi
		else
			echo -e "please specify zip/rar to use with --riivolution=<path>"
			exit 21
		fi
	fi
	echo "*** >> status: ${x}"

}

optparse () {

xcount=0
pcount=$#

while [[ $xcount -lt $pcount ]]; do
	case $1 in

		--iso* )
			ISO_PATH=${1/*=}
			ISO_EXT=${ISO_PATH//*./}

			if [[ -e "${ISO_PATH}" ]]; then
				ln -sf "${ISO_PATH}" BASE.${ISO_EXT}
				IMAGE=BASE.${ISO_EXT}
			else
				echo -e "ISO not found"
				exit 15
			fi
		;;

		--rom* )
			ROM_PATH=${1/*=}
			ROM_EXT=${ROM_PATH//*./}

			if [[ -e "${ROM_PATH}" ]]; then
				ln -sf "${ROM_PATH}" BASE.${ROM_EXT}
				IMAGE=BASE.${ROM_EXT}
			else
				echo -e "ROM not found"
				exit 15
			fi
		;;

		--riivolution* )
			RIIVOLUTION=${1/*=}
			if [[ -e "${RIIVOLUTION}" ]]; then
				${UNP} "${RIIVOLUTION}" >/dev/null
			else
				echo -e "Riivolution patch ${RIIVOLUTION} not found."
				exit 21
			fi
		;;

		--patch*  )
			PATCH=${1/*=}
			if [[ -e "${PATCH}" ]]; then
				${UNP} "${PATCH}" >/dev/null
			else
				echo -e "PATCH patch ${PATCH} not found."
				exit 21
			fi
		;;

		--customid* )
			CUSTOMID=${1/*=}
			if [[ ${#CUSTOMID} != 6 ]]; then
				echo -e "CustomID ${CUSTOMID} needs to have 6 digits"
				exit 39
			fi
		;;

		--download )
			PATCHIMAGE_RIIVOLUTION_DOWNLOAD=TRUE
		;;

		--soundtrack )
			DOWNLOAD_SOUNDTRACK=TRUE
		;;

		--version=* )
			VERSION=${1/*=}
			case ${VERSION} in
				EURv1 )
					REG_LETTER=P
				;;

				EURv2 )
					REG_LETTER=P
				;;

				USAv1 )
					REG_LETTER=E
				;;

				USAv2 )
					REG_LETTER=E
				;;

				JPNv1 )
					REG_LETTER=J
				;;

				* )
					echo -e "unrecognized game version: ${VERSION}"
					exit 27
				;;
			esac
		;;

		--sharesave )
			PATCHIMAGE_SHARE_SAVE=TRUE
		;;

		--game* )
			GAME=${1/*=}
		;;

		--banner=* )
			BANNER=${1/*=}
			BANNER_EXT=${BANNER//*./}
			if [[ ${BANNER_EXT} != "bnr" ]]; then
				echo "given banner (${BANNER}) is not a .bnr file!"
				exit 33
			fi
		;;

		--download-banner )
			PATCHIMAGE_BANNER_DOWNLOAD=TRUE
		;;

		"" | --help )
			echo -e "patchimage 4.0 (2013-10-11)

	(c) 2013 Christopher Roy Bratusek <nano@tuxfamily.org>
	patchimage creates wbfs images from riivolution patches.

--game=<gamename/gameletter>		| specify game you want to create
--iso/--rom=/home/test/<Image>		| specify which ISO/ROM to use for building
--riivolution/--patch=<Patch>		| specify path to Riivolution/Patch files
--version=EURv1,EURv2,USAv1,USAv2,JPNv1	| specify your game version
--customdid=SMNP02			| specify a custom ID to use for the game
--sharesave				| let modified game share savegame with original game
--download				| download riivolution patchfiles
--soundtrack				| download soundtrack (if available) and exit
--banner=<banner.bnr>			| use a custom banner (riivolution games)
--download-banner			| download a custom banner (if available)"
			exit 0
		;;
	esac
	shift
	xcount=$(($xcount+1))
done

}
