# ReaWhisper

Simple script to run OpenAI Whisper to transcribe audio items directly from REAPER into .srt files and imports the subtitles in a track as items with notes. 

## How to install

First, you need to install Whisper in your system, and then configure the script to point to the path where you installed it. 
You will need Python 3.8-3.11 installed in your system.
Then I recommend you to create a new folder somewhere and inside it, create a pythonvirtual environment for Whisper. This way all the requirements you install here are stored only for this environment. Check python virtual environment for more details on how to create them.
inside the Whisper folder, run this:
    
    python -m venv ./.venv

activate the environment on Linux and MacOS:

    source ./.venv/bin/activate

on windows:

    # In cmd.exe
    venv\Scripts\activate.bat
    # In PowerShell
    venv\Scripts\Activate.ps1

now that you are in this .venv, you can install Whisper here:

To install Whisper following instructions from their github [readme](https://github.com/openai/whisper/blob/main/README.md)
You can download and install (or update to) the latest release of Whisper with the following command:

    pip install -U openai-whisper

Patiently wait for it to download and install all the requirements. 
now if you type whisper it would run. 

With Whisper installed and running, the next step is to install the script into your REAPER resources folder in Scripts/HeDaScripts/ReaWhisper folder. using git clone:

change directory to the Scripts/HeDaScripts directory
and run:

    git clone https://github.com/HeDaScripts/ReaWhisper.git

this will create the ReaWhisper directory inside HeDaScripts and download all the files there. 
If you need to update it in the future, you can use:

    git pull

Now you can add the .lua files in REAPER actions list and run it. First time it will copy the settings file to your custom settings folder for the script. and open it for editing. You have to change the whisperbin inside the settings file to point to the whisper executable. On windows you should include the .exe extension. And that's it. It is installed and it should work.


