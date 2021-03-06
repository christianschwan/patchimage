#!/bin/bash
#
# create wbfs image from riivolution patch
#
# Christopher Roy Bratusek <nano@tuxfamily.org>
#
# License: GPL v3

if [[ ! -d ${PWD}/workdir ]]; then
	mkdir ${PWD}/workdir
else
	rm -rf ${PWD}/workdir/*
fi

if [[ -d ${PWD}/script.d ]]; then
	PATCHIMAGE_SCRIPT_DIR=../script.d
	PATCHIMAGE_PATCH_DIR=../patches
	PATCHIMAGE_TOOLS_DIR=../tools
else
	PATCHIMAGE_SCRIPT_DIR=/usr/share/patchimage/script.d
	PATCHIMAGE_PATCH_DIR=/usr/share/patchimage/patches
	PATCHIMAGE_TOOLS_DIR=/usr/share/patchimage/tools
fi

cd ${PWD}/workdir

PATCHIMAGE_RIIVOLUTION_DIR=${PWD}
PATCHIMAGE_WBFS_DIR=${PWD}
PATCHIMAGE_AUDIO_DIR=${PWD}

if [[ -e $HOME/.patchimage.rc ]]; then
	source $HOME/.patchimage.rc
fi

source ${PATCHIMAGE_SCRIPT_DIR}/common.sh
check_directories

setup_tools

optparse "${@}"

if [[ ! ${GAME} ]]; then
	ask_game
fi

case ${GAME} in

	a | A | NewerSMB | NewerSMBW )
		source ${PATCHIMAGE_SCRIPT_DIR}/newersmb.sh
	;;

	b | B | NewerSummerSun )
		source ${PATCHIMAGE_SCRIPT_DIR}/newersummersun.sh
	;;

	c | C | ASMBW | AnotherSMBW )
		source ${PATCHIMAGE_SCRIPT_DIR}/anothersmb.sh
	;;

	d | D | HolidaySpecial | "Newer: Holiday Special" )
		source ${PATCHIMAGE_SCRIPT_DIR}/newerholiday.sh
	;;

	e | E | Cannon | "Cannon SMBW" )
		source ${PATCHIMAGE_SCRIPT_DIR}/cannon.sh
	;;

	f | F | ESBW | "Epic Super Bowser World" )
		source ${PATCHIMAGE_SCRIPT_DIR}/epicbowserworld.sh
	;;

	g | G | Koopa | "Koopa Country" )
		source ${PATCHIMAGE_SCRIPT_DIR}/koopacountry.sh
	;;

	h | H | NSMBW4 | "New Super Mario Bros. 4" )
		source ${PATCHIMAGE_SCRIPT_DIR}/nsmbw4.sh
	;;

	i | I | Retro | "Retro Remix" )
		source ${PATCHIMAGE_SCRIPT_DIR}/retroremix.sh
	;;

	j | J | WinterMoon | "Super Mario: Mushroom Adventure PLUS - Winter Moon" )
		source ${PATCHIMAGE_SCRIPT_DIR}/wintermoon.sh
	;;

	k | K | NSMBW3 | "NSMBW3: The Final Levels" )
		source ${PATCHIMAGE_SCRIPT_DIR}/nsmbw3.sh
	;;

	l | L | SMV | "Super Mario Vacation" )
		source ${PATCHIMAGE_SCRIPT_DIR}/summervacation.sh
	;;

	m | M | ASLM | "Awesomer Super Luigi Mini" )
		source ${PATCHIMAGE_SCRIPT_DIR}/awesomersuperluigi.sh
	;;

	1 | ParallelWorlds | "The Legend of Zelda: Parallel Worlds" )
		source ${PATCHIMAGE_SCRIPT_DIR}/parallelworlds.sh
	;;

	* )
		echo -e "specified Game ${GAME} not recognized"
		exit 9
	;;

esac

case ${GAME_TYPE} in
	"RIIVOLUTION" )
		show_notes
		rm -rf ${WORKDIR}
		if [[ ${DOWNLOAD_SOUNDTRACK} == TRUE ]]; then
			echo "\n*** 1) download_soundtrack"
			download_soundtrack
			exit 0
		fi
		echo -e "\n*** 1) check_input_image"
		check_input_image
		echo "*** 2) check_input_image_special"
		check_input_image_special
		echo "*** 3) check_riivolution_patch"
		check_riivolution_patch

		echo "*** 4) extract game"
		${WIT} extract ${IMAGE} ${WORKDIR} --psel=DATA -q || exit 51

		echo "*** 5) detect_game_version"
		detect_game_version
		rm -f ${GAMEID}.wbfs ${CUSTOMID}.wbfs
		echo "*** 6) place_files"
		place_files || exit 45

		echo "*** 7) download_banner"
		download_banner
		echo "*** 8) apply_banner"
		apply_banner

		echo "*** 9) dolpatch"
		dolpatch

		if [[ ${CUSTOMID} ]]; then
			GAMEID = ${CUSTOMID}
		fi

		if [[ ${PATCHIMAGE_SHARE_SAVE} == "TRUE" ]]; then
			TMD_OPTS=""
		else
			TMD_OPTS="--tt-id=K"
		fi

		echo "*** 10) rebuild game"
		${WIT} cp -q -B ${WORKDIR} ${GAMEID}.wbfs --disc-id=${GAMEID} ${TMD_OPTS} --name "${GAMENAME}" || exit 51

		if [[ -d ${PATCHIMAGE_WBFS_DIR} && ${PATCHIMAGE_WBFS_DIR} != ${PWD} ]]; then
			echo "*** 11) store game"
			mv ${GAMEID}.wbfs "${PATCHIMAGE_WBFS_DIR}"/
		fi

		echo "*** 12) remove workdir"
		cd ..
		rm -rf workdir

		echo -e "\n >>> ${GAMENAME} saved as: ${PATCHIMAGE_WBFS_DIR}/${GAMEID}.wbfs\n"

	;;

	"IPS" )
		show_notes
		check_input_rom

		if [[ -f ${PATCH} ]]; then
			ext=${ROM/*.}
			cp "${ROM}" "${GAMENAME}.${ext}"
			${IPS} a "${PATCH}" "${GAMENAME}.${ext}" || exit 51
		else
			echo -e "error: patch (${PATCH}) could not be found"
		fi
	;;
esac
