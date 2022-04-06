#!/bin/bash


get_username_and_model () {
echo "This script has been tested on Ubuntu 20LTS, running on AWS-EC2 and Azure."
echo "Intro: get username and model"
cd $HOME
echo Enter the ubuntu username. For AWS, the default is 'ubuntu'. For Azure default is 'azureuser'
read userName

echo Enter URL to .h5 model file. Or press ENTER to upload file later, using FTP or scp
echo "(it must be a direct download link, not a Google or Dropbox webpage)"
echo "For Google Drive, this site can generate direct link: sites.google.com/site/gdocs2direct/"
read pathToFile
# below: if length of string is greater than zero, then run wget
if [ ${#pathToFile} -gt 0 ]
then
        sudo wget --no-check-certificate -O mymodel.h5 $pathToFile
fi

}


f3_installPython () {
echo "Step 3. install python"
sudo apt update
sudo apt -y upgrade
# try without virtual environment
#sudo apt install python3-venv
sudo apt install -y python3-pip
}

f4_createFolder () {

echo "Step 4. create folder and move the .h5 file there"
cd $HOME
sudo rm -r predict ||: # remove or return true if not exist
mkdir predict
sudo mv ./mymodel.h5 ./predict/  # move the .h5 file into the new folder.

#python3 -m venv venv
#source venv/bin/activate
}

f5_installFlask () {
echo "Step 5. Install Flask (Python webserver)"
yes | pip install Flask

}


f6_createWebserverScript () {
echo "Step 6.Create a Python webserver script"
cd $HOME/predict
echo "from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
	return 'Hello World! Prediction is coming…'

if __name__ == '__main__':
	app.run()" > app.py

}


f7_installGunicorn () {
echo "Step 7. Install Gunicorn WSGI server to serve the Flask app"
yes | pip install gunicorn
}


f8_useSystemd () {
echo "Setp 8. use systemd to manage Gunicorn\n"
# was venv/bin/gunicorn Trying without venv
sudo touch /etc/systemd/system/predict.service
sudo chmod 777 /etc/systemd/system/predict.service
sudo echo "[Unit]
Description=Gunicorn instance for a simple prediction app
After=network.target
[Service]
User=$userName
Group=www-data
WorkingDirectory=/home/$userName/predict
ExecStart=/home/$userName/.local/bin/gunicorn -b localhost:8000 app:app
Restart=always
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/predict.service
sudo systemctl daemon-reload
sudo systemctl start predict
sudo systemctl enable predict  
}

f9_installNginx () {
echo "Step 9 Install/run Nginx webserver to accept and route request to Gunicorn"
sudo apt -y install nginx
sudo systemctl start nginx
sudo systemctl enable nginx
sudo chmod 777 /etc/nginx/sites-available
sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default_old
sudo echo "upstream flaskpredict {
    server 127.0.0.1:8000;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;

    # Add index.php to the list if you are using PHP
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        proxy_pass http://flaskpredict;
    }

}
" > /etc/nginx/sites-available/default
sudo chmod 644 /etc/nginx/sites-available
sudo systemctl restart nginx
}

f10_installTensorflow () {
echo "Step 10. Install Tensorflow\n"
yes | pip install --upgrade tensorflow
python3 -c 'import tensorflow as tf; print(tf.__version__)'  # check installation
}

f11_createHTMLtemplate () {
echo "Step 11. Prepare a HTML template file (index.html)"
cd $HOME/predict
sudo rm -r templates ||: # remove if present
mkdir templates 
cd templates
echo "<html>
    <body>
        <h2>NAND gate Predictor, made with Keras, Tensorflow</h2>
    <form method='post'>
      Input A: <input type='text' name='in1' placeholder='1 or 0' /></br>
      Input B: <input type='text' name='in2' placeholder='1 or 0' /></br>
      <input type='submit'/>
    </form>
<h3>The result is {{ result }}</h3>
</body>
</html>
" > index.html
}


f13_completeScript () {
echo "Step 13 Complete the script app.py"

cd $HOME/predict
echo "from flask import Flask, render_template, request
from tensorflow.keras.models import load_model
import numpy as np
app = Flask(__name__)

@app.route('/',methods=['post','get']) # will use get for the first page-load, post for the form-submit
def predict(): # this function can have any name
    model = load_model('mymodel.h5') # the mymodel.h5 file was created in Colab, downloaded and uploaded using Filezilla
    in1 = request.form.get('in1') # get the two numbers from the request object
    in2 = request.form.get('in2')
    if in1 == None or in2 == None: # check if any number is missing
        return render_template('index.html', result='No input(s)')
        # calling render_template will inject the variable 'result' and send index.html to the browser
    else:
        arr = np.array([[ float(in1),float(in2) ]]) # cast string to decimal number, and make 2d numpy array.
        predictions = model.predict(arr) # make new prediction
        return render_template('index.html', result=str(predictions[0][0]))
        # the result is set, by asking for row=0, column=0. Then cast to string.

if __name__ == '__main__':
    app.run()
" > app.py


sudo systemctl restart predict

}

f14_finalMessage () {
echo ""
echo "You must change these two files to handle your project requirements:"
echo "~/predict/templates/index.html   # design the HTML form and layout"
echo " ~/predict/app.py   # handles input from the HTML form and send response to browser"
echo ""
echo "Installation of Pyton3, pip, Flask, Nginx, Gunicorn and Tensorflow complete"
echo "Also a systemd service has been created, called predict. It will autostart on reboot"
echo ""
echo "Script by: Jon Eikholm, KEA jone@kea.dk 2022"
}


get_username_and_model
f3_installPython
f4_createFolder
f5_installFlask
f6_createWebserverScript
f7_installGunicorn
f8_useSystemd
f9_installNginx
f10_installTensorflow
f11_createHTMLtemplate
f13_completeScript
f14_finalMessage

# now enter the cloud instance's IP into a browser. It should show a
# webpage, saying "Predictor..."
# This requires the .h5 file being uploaded.




