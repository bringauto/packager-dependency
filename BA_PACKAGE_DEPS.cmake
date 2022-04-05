##
#
# BringAuto Package Dependencies scripts.
#
# Pack dependencies of the given target as a part
# of the package.
#



##
#
# Functio goes thru targetlink dependencies, gather all
# imported shared libraries, install them and repair RPATH.
#
# The install dir for all depdnencies is set from CMDEF_LIBARRY_INSTALL_DIR
#
# <function> (
#   <target> <install_dir>
# )
#
FUNCTION(BRINGAUTO_PACKAGE_DEPS_IMPORTED target)
    SET(install_dir "${CMDEF_LIBRARY_INSTALL_DIR}")
	GET_TARGET_PROPERTY(link_libraries           ${target} LINK_LIBRARIES)
	GET_TARGET_PROPERTY(interface_link_libraries ${target} INTERFACE_LINK_LIBRARIES)

	SET(link_libraries_list)
	IF(NOT "${link_libraries}" STREQUAL "Link_libraries-NOTFOUND")
		LIST(APPEND link_libraries_list ${link_libraries})
	ENDIF()
	IF(NOT "${interface_link_libraries}" STREQUAL "interface_link_libraries-NOTFOUND")
		LIST(APPEND link_libraries_list ${interface_link_libraries})
	ENDIF()

	FOREACH(library IN LISTS link_libraries_list)
		IF(NOT TARGET ${library})
			CONTINUE()
		ENDIF()

		GET_TARGET_PROPERTY(library_type ${library} TYPE)

		SET(filename)
		STRING(TOUPPER "${CMAKE_BUILD_TYPE}" build_upper)
		IF("${library_type}" STREQUAL "SHARED_LIBRARY")
			INSTALL(IMPORTED_RUNTIME_ARTIFACTS ${library} DESTINATION ${install_dir})
			GET_TARGET_PROPERTY(filename ${library} IMPORTED_SONAME_${build_upper})
		ELSEIF("${library_type}" STREQUAL "UNKNOWN_LIBRARY")
			_BRINGAUTO_PACKAGE_DEPS_GET_IMPORTED_LOCATION(${library} filepath)
			IF(NOT filepath)
				MESSAGE(WARNING "Cannot install ${library}")
				CONTINUE()
			ENDIF()
			GET_FILENAME_COMPONENT(filename "${filepath}" NAME)
			STRING(REGEX MATCH "^[^.]+.so[.0-9]*$" is_shared "${filename}")
			IF(NOT is_shared)
				CONTINUE()
			ENDIF()
			INSTALL(FILES "${filepath}" DESTINATION ${install_dir})
		ELSE()
			BRINGAUTO_PACKAGE_DEPS_IMPORTED(${library} ${install_dir})
			CONTINUE()
		ENDIF()

		INSTALL(CODE "SET(library     ${filename})")
		INSTALL(CODE "SET(install_dir ${install_dir})")
		INSTALL(CODE [[
				FIND_PROGRAM(patchelf patchelf REQUIRED)
				EXECUTE_PROCESS(
					COMMAND           ${patchelf} --set-rpath '$ORIGIN' ${install_dir}/${library}
					RESULT_VARIABLE    result
					WORKING_DIRECTORY "${CMAKE_INSTALL_PREFIX}"
				)
				IF(NOT result EQUAL 0)
					MESSAGE(FATAL_ERROR "Cannot update RPATH for ${install_dir}/${library}")
				ENDIF()
			]])
	ENDFOREACH()
ENDFUNCTION()



## Helper
#
# Function returns IMPORTED_LOCATION (or IMPORTED_LOCATION_${build_type_uppercase})
# in the ${output_var} variable.
#
# If no IMPORTED_LOCATION found the ${output_var} is unset in the calling context.
#
# <function> (
#   <target> <build_type> <output_var>
# )
#
FUNCTION(_BRINGAUTO_PACKAGE_DEPS_GET_IMPORTED_LOCATION_FOR_BUILD_TYPE target build_type output_var)
	STRING(TOUPPER "${build_type}" build_upper)
	GET_TARGET_PROPERTY(imported_location_${build_upper} ${target} IMPORTED_LOCATION_${build_upper})
	GET_TARGET_PROPERTY(imported_location ${target} IMPORTED_LOCATION)
	IF(NOT "${imported_location_${build_upper}}" STREQUAL "imported_location_${build_upper}-NOTFOUND")
		SET(${output_var} "${imported_location_${build_upper}}" PARENT_SCOPE)
	ELSEIF(NOT "${imported_location}" STREQUAL "imported_location-NOTFOUND")
		SET(${output_var} "${imported_location}" PARENT_SCOPE)
	ELSE()
		UNSET(${output_var} PARENT_SCOPE)
	ENDIF()
ENDFUNCTION()



## Helper
#
# It tries to get IMPORTED_LOCATION from the target.
# 
# If the IMPORTED_LOCATION property does not exist try to find
# IMPORTED_LOCATION_${CMAKE_BUILD_TYPE}.
#
# IMPORTED_LOCATION_${CMAKE_BUILD_TYPE} does not exist try to crawl thru
# all supported build types (except ${CMAKE_BUILD_TYPE}).
# Function returns first existing IMPORTED_LOCATION_<build_type>.
#
# IF not IMPORTED_LOCATION found then the <output_var> is unset in the calling context.
#
# <function> (
#   <target> <output_var>
# )
#
FUNCTION(_BRINGAUTO_PACKAGE_DEPS_GET_IMPORTED_LOCATION target output_var)
	SET(filepath)
	_BRINGAUTO_PACKAGE_DEPS_GET_IMPORTED_LOCATION_FOR_BUILD_TYPE(${target} ${CMAKE_BUILD_TYPE} filepath)
	IF(NOT filepath)
		SET(build_type_list ${CMDEF_BUILD_TYPE_LIST_UPPERCASE})
		LIST(REMOVE_ITEM build_type_list ${CMAKE_BUILD_TYPE})
		FOREACH(build_type IN LISTS build_type_list)
			_BRINGAUTO_PACKAGE_DEPS_GET_IMPORTED_LOCATION_FOR_BUILD_TYPE(${target} ${build_type} filepath)
			IF(filepath)
				BREAK()
			ENDIF()
		ENDFOREACH()
	ENDIF()
	IF(filepath)
		SET(${output_var} "${filepath}" PARENT_SCOPE)
	ENDIF()
	UNSET(${output_var} PARENT_SCOPE)
ENDFUNCTION()
