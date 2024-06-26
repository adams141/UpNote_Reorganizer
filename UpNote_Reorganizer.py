import os
import shutil
import frontmatter #pip install python-frontmatter
import logging
logging.basicConfig(level=logging.INFO)

baseDir = "Notes"
if not os.path.isdir(baseDir):
    os.mkdir(baseDir)


for file in os.listdir(os.getcwd()):
    if file.endswith(".md"):

        logging.info("opened: {f}".format(f=file))

        note = frontmatter.load(file)

        if 'categories' in note:
            for c in note['categories']:

                directory = c.replace(" / ","/")

                dest = os.path.join(baseDir, directory)

                logging.info("copying {f} to {d}".format(f=file, d=dest))

                if not os.path.isdir(dest):
                    os.makedirs(dest)
                    
                shutil.copy(file, dest)
        else:

            logging.info("no category, copying {f} to {d}".format(f=file, d=baseDir))

            shutil.copy(file, baseDir)
