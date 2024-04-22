# UpNote Reorganizer
Put an Upnote export back into a folder heirarchy

### Need
When you export your notes in markdown format, they are all in one folder. This puts them back into the folder structure you had in UpNote. *note: if you have a note in multiple notebooks, you will end up with multiple copies*

### Requirements
uses [python-frontmatter](https://github.com/eyeseast/python-frontmatter)

    pip install python-frontmatter

### Usage
- From upnote, export all notes as markdown to a folder. (options -> general -> Export All Notes)  check the option to include extra info
- Put UpNote_Reorganizer.py in that folder  
- Run `python UpNote_Reorganizer.py`
