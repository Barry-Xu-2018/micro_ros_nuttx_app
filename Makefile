include $(APPDIR)/Make.defs
-include $(SDKDIR)/Make.defs

MAINSRC = microros_main.c

CFLAGS += ${shell $(INCDIR) "$(CC)" $(APPDIR)/microros/include}

PROGNAME = microros
PRIORITY = SCHED_PRIORITY_DEFAULT
STACKSIZE = 6000
# MODULE = $(CONFIG_MICROROSLIB)

.depend: libmicroros.a

all::
	rm -rf include; \
	cp -R micro_ros_src/install/include include; \
	mkdir -p temp; cd temp; \
	ar x ../libmicroros.a; \
	for f in *; do \
		echo "Adding $$f"; \
		ar r ../../libapps.a $$f; \
	done; \
	cd ..; rm -rf temp;

clean::
	rm -rf libmicroros.a; \
	rm -rf include; \
	rm -rf toolchain.cmake; \
	rm -rf micro_ros_dev; \
	rm -rf micro_ros_src;

FORMATED_CXXFLAGS := $(subst /,\/,$(CXXFLAGS))
FORMATED_CXXFLAGS := $(subst ",,$(FORMATED_CXXFLAGS))

FORMATED_CFLAGS := $(subst /,\/,$(CFLAGS))
FORMATED_CFLAGS := $(subst ",,$(FORMATED_CFLAGS))

toolchain.cmake: toolchain.cmake.in
	rm -rf toolchain.cmake; \
	cat toolchain.cmake.in | \
		sed "s/@NUTTX_TOPDIR@/$(subst /,\/,$(TOPDIR))/g" | \
		sed "s/@NUTTX_APPDIR@/$(subst /,\/,$(APPDIR))/g" | \
		sed "s/@CMAKE_C_COMPILER@/$(subst /,\/,$(CC))/g" | \
		sed "s/@CMAKE_CXX_COMPILER@/$(subst /,\/,$(CXX))/g" | \
		sed "s/@ARCH_C_FLAGS@/$(FORMATED_CFLAGS)/g" | \
		sed "s/@ARCH_CPP_FLAGS@/$(FORMATED_CXXFLAGS)/g"  \
	> toolchain.cmake

micro_ros_dev/install:
	rm -rf micro_ros_dev; \
	mkdir micro_ros_dev; cd micro_ros_dev; \
	git clone -b foxy https://github.com/ament/ament_cmake src/ament_cmake; \
	git clone -b foxy https://github.com/ament/ament_lint src/ament_lint; \
	git clone -b foxy https://github.com/ament/ament_package src/ament_package; \
	git clone -b foxy https://github.com/ament/googletest src/googletest; \
	git clone -b foxy https://github.com/ros2/ament_cmake_ros src/ament_cmake_ros; \
	colcon build; 

micro_ros_src/src:
	rm -rf micro_ros_src; \
	mkdir micro_ros_src; cd micro_ros_src; \
	git clone -b foxy https://github.com/eProsima/micro-CDR src/micro-CDR; \
	git clone -b foxy https://github.com/eProsima/Micro-XRCE-DDS-Client src/Micro-XRCE-DDS-Client; \
	git clone -b foxy https://github.com/micro-ROS/rcl src/rcl; \
	git clone -b foxy https://github.com/ros2/rclc src/rclc; \
	git clone -b foxy https://github.com/micro-ROS/rcutils src/rcutils; \
	git clone -b foxy https://github.com/micro-ROS/micro_ros_msgs src/micro_ros_msgs; \
	git clone -b foxy https://github.com/micro-ROS/rmw-microxrcedds src/rmw-microxrcedds; \
	git clone -b foxy https://github.com/micro-ROS/rosidl_typesupport src/rosidl_typesupport; \
	git clone -b foxy https://github.com/micro-ROS/rosidl_typesupport_microxrcedds src/rosidl_typesupport_microxrcedds; \
	git clone -b master https://github.com/ros2/tinydir_vendor src/tinydir_vendor; \
	git clone -b foxy https://github.com/ros2/rosidl src/rosidl; \
	git clone -b foxy https://github.com/ros2/rmw src/rmw; \
	git clone -b foxy https://github.com/ros2/rcl_interfaces src/rcl_interfaces; \
	git clone -b foxy https://github.com/ros2/rosidl_defaults src/rosidl_defaults; \
	git clone -b foxy https://github.com/ros2/unique_identifier_msgs src/unique_identifier_msgs; \
	git clone -b foxy https://github.com/ros2/common_interfaces src/common_interfaces; \
	git clone -b foxy https://github.com/ros2/test_interface_files src/test_interface_files; \
	git clone -b foxy https://github.com/ros2/rmw_implementation src/rmw_implementation; \
	git clone -b foxy_microros https://gitlab.com/micro-ROS/ros_tracing/ros2_tracing src/ros2_tracing; \
	touch src/rosidl/rosidl_typesupport_introspection_c/COLCON_IGNORE; \
    touch src/rosidl/rosidl_typesupport_introspection_cpp/COLCON_IGNORE; \
    touch src/rclc/rclc_examples/COLCON_IGNORE; \
	touch src/rcl/rcl_yaml_param_parser/COLCON_IGNORE; \
	cp -rf ../extra_packages src/extra_packages || :;

micro_ros_src/install: toolchain.cmake micro_ros_dev/install micro_ros_src/src
	cd micro_ros_src; \
	. $(APPDIR)/microros//micro_ros_dev/install/local_setup.sh; \
	colcon build \
		--merge-install \
		--packages-ignore-regex=.*_cpp \
		--metas $(APPDIR)/microros/colcon.meta $(APP_COLCON_META) \
		--cmake-args \
		"--no-warn-unused-cli" \
		-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=OFF \
		-DTHIRDPARTY=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TESTING=OFF \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_TOOLCHAIN_FILE=$(APPDIR)/microros/toolchain.cmake \
		-DCMAKE_VERBOSE_MAKEFILE=OFF; \

libmicroros.a: micro_ros_src/install
	mkdir -p libmicroros; cd libmicroros; \
	for file in $$(find $(APPDIR)/microros/micro_ros_src/install/lib/ -name '*.a'); do \
		folder=$$(echo $$file | sed -E "s/(.+)\/(.+).a/\2/"); \
		mkdir -p $$folder; cd $$folder; ar x $$file; \
		for f in *; do \
			mv $$f ../$$folder-$$f; \
		done; \
		cd ..; rm -rf $$folder; \
		# cd ..; \
	done ; \
	ar rc -s libmicroros.a *.obj; cp libmicroros.a ..; \
	cd ..; rm -rf libmicroros; \
	# cd ..; \
	cp -R micro_ros_src/install/include include;
	

include $(APPDIR)/Application.mk



