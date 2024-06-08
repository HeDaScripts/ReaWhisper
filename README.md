# ReaWhisper

Simple script to run OpenAI Whisper or Whisper.cpp to transcribe audio items directly from REAPER into .srt files and imports the subtitles in a track as items with notes. 

## How to install
You need to install OpenAI Whisper or Whisper.cpp. In my tests, whisper.cpp runs faster and it may be easier to install.

# Whisper.cpp installation (recommended)
TO install Whisper.cpp you can follow the instructions in their page: 
https://github.com/ggerganov/whisper.cpp

- Go to the directory where you want to install it and run:
    
        git clone https://github.com/ggerganov/whisper.cpp.git

    This downloads the source code into a whisper.cpp folder. Or if you don't have git, just download the zip file from github and extract it.

- Download the gglm bin models from here https://huggingface.co/ggerganov/whisper.cpp/tree/main
and copy them to the models directory inside whisper.cpp.  You don't need to download all the models, only the ones to be used.

    Alternatively you can go to the whisper.cpp directory and run (base.en is a model name example):
    
        bash ./models/download-ggml-model.sh base.en

- Compile it, check the whisper cpp readme for more options

    Linux:
    
        # build the main example
        make
    
        # test
        ./main -h
    
    Windows:
    
    You need [cmake](https://cmake.org/download/), and inside whisper.cpp folder run:
    
        # build the main example (for CPU)
        cmake . --fresh
        msbuild ALL_BUILD.vcxproj /p:Configuration=Release
        
    This will create whisper.cpp/bin/Release/main.exe and whisper.dll. Go to the Release folder (or move both files to the root) and run:
    
        # test
        main -h

If the main -h command gives you the options information, then it works and it is ready.

- To convert the audio files into the audio whisper.cpp reads, you also need to install ffmpeg package in your system. install it from your favorite package manager and test it

        ffmpeg -h 

Now you only need to install ReaWhisper and configure the settings file and set the whispercpp to point to the main executable in your whisper.cpp directory.

# OpenAI Whisper (optional)
If you want you can also use the original OpenAI Whisper and then configure the script to point to the path where you installed it. 
You will need Python 3.8-3.11 installed in your system.
Then I recommend you to create a new folder somewhere and inside it, create a pythonvirtual environment for Whisper. This way all the requirements you install here are stored only for this environment. Check python virtual environment for more details on how to create them.
inside the Whisper folder, run this:
    
    python -m venv ./.venv

activate the environment on Linux and MacOS:

    source ./.venv/bin/activate

On windows:

    # In cmd.exe
    venv\Scripts\activate.bat
    # In PowerShell
    venv\Scripts\Activate.ps1

Now that you are in this .venv, you can install Whisper here:

To install Whisper following instructions from their github [readme](https://github.com/openai/whisper/blob/main/README.md)
You can download and install (or update to) the latest release of Whisper with the following command:

    pip install -U openai-whisper

Patiently wait for it to download and install all the requirements. 
now if you type whisper it would run. 


# Installing and configuring ReaWhisper

The next step is to install the script into your REAPER resources folder in Scripts/HeDaScripts/ReaWhisper folder. using git clone:

change directory to the Scripts/HeDaScripts directory inside REAPER resources
and run:

    git clone https://github.com/HeDaScripts/ReaWhisper.git

This will create the ReaWhisper directory inside HeDaScripts and download all the files there. 
If you need to update it in the future, you can use:

    git pull

Now you can add the .lua files in REAPER actions list and run it. First time it will copy the settings file to your custom settings folder for the script. and open it for editing. You have to change the whisperbin inside the settings file to point to the whisper executable. Or if you are running whisper.cpp, then you must set the whispercpp line to point to the main whisper.cpp executable as it is explained inside the settings file. On windows you should include the .exe extension in the path. 
In the Settings file, also, make sure you set the model you want to use, by default is set to model = "base.en", but change it to the one you want and maybe remove the default language from English to None if you want the multilingual model instead of the .en models that are only english.

And that's it. It is installed and it should work.
