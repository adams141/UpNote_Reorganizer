import os
import shutil
import frontmatter #pip install python-frontmatter

baseDir = "Notes"
if not os.path.isdir(baseDir):
    os.mkdir(baseDir)


for file in os.listdir(os.getcwd()):
    if file.endswith(".md"):

        note = frontmatter.load(file)

        if 'categories' in note:
            for c in note['categories']:

                directory = c.replace(" / ","/")

                dest = os.path.join(baseDir, directory)

                if not os.path.isdir(dest):
                    os.makedirs(dest)
                    
                shutil.copy(file, dest)
        

