#!/bin/bash

# Original script/credit belongs to Pete Goodliffe:
# http://accu.org/index.php/journals/1594

# Script edited/adapted for use in this project (AQGridView) by Mark Hurley

xcodebuild               	\
	-configuration Release 	\
	-target "AQGridView"    \
	-sdk iphoneos4.2

xcodebuild               	\
	-configuration Release 	\
	-target "AQGridView"    \
	-sdk iphonesimulator4.2

# Define these to suit your nefarious purposes  
                     FRAMEWORK_NAME=AQGridView
                  FRAMEWORK_VERSION=A
          FRAMEWORK_CURRENT_VERSION=1
    FRAMEWORK_COMPATIBILITY_VERSION=1
                         BUILD_TYPE=Release
 
    # Where we'll put the build framework.  
    # The script presumes we're in the project root  
    # directory. Xcode builds in "build" by default  
    FRAMEWORK_BUILD_PATH="build/Framework"  
 
    # Clean any existing framework that might be there  
    # already  
    echo "Framework: Cleaning framework..."  
    [ -d "$FRAMEWORK_BUILD_PATH" ] && \
      rm -rf "$FRAMEWORK_BUILD_PATH"  

    # This is the full name of the framework we'll  
    # build  
    FRAMEWORK_DIR=$FRAMEWORK_BUILD_PATH/$FRAMEWORK_NAME.framework  
 
    # Build the canonical Framework bundle directory  
    # structure  
    echo "Framework: Setting up directories..."  
    mkdir -p $FRAMEWORK_DIR  
    mkdir -p $FRAMEWORK_DIR/Versions  
    mkdir -p $FRAMEWORK_DIR/Versions/$FRAMEWORK_VERSION  
    mkdir -p $FRAMEWORK_DIR/Versions/$FRAMEWORK_VERSION/Resources  
    mkdir -p $FRAMEWORK_DIR/Versions/$FRAMEWORK_VERSION/Headers  

    echo "Framework: Creating symlinks..."
    ln -s $FRAMEWORK_VERSION $FRAMEWORK_DIR/Versions/Current
    ln -s Versions/Current/Headers $FRAMEWORK_DIR/Headers
    ln -s Versions/Current/Resources $FRAMEWORK_DIR/Resources
    ln -s Versions/Current/$FRAMEWORK_NAME $FRAMEWORK_DIR/$FRAMEWORK_NAME

    # Check that this is what your static libraries
    # are called
    FRAMEWORK_INPUT_ARM_FILES="build/$BUILD_TYPE-iphoneos/libAQGridView.a"
    FRAMEWORK_INPUT_I386_FILES="build/$BUILD_TYPE-iphonesimulator/libAQGridView.a"

    # The trick for creating a fully usable library is  
    # to use lipo to glue the different library  
    # versions together into one file. When an  
    # application is linked to this library, the  
    # linker will extract the appropriate platform  
    # version and use that.  
    # The library file is given the same name as the  
    # framework with no .a extension.  
    echo "Framework: Creating library..."  
    lipo \
      -create \
      "$FRAMEWORK_INPUT_ARM_FILES" \
      "$FRAMEWORK_INPUT_I386_FILES" \
      -o "$FRAMEWORK_DIR/Versions/Current/$FRAMEWORK_NAME"

    # Now copy the final assets over: your library  
    # header files and the plist file  
    echo "Framework: Copying assets into current version..."  
#    cp Include/$FRAMEWORK_NAME/* $FRAMEWORK_DIR/  
#       Headers/  
	cp Classes/*.h $FRAMEWORK_DIR/Headers
    cp Resources/Framework.plist $FRAMEWORK_DIR/Resources/Info.plist 

