from statistics import mode
from flask import Flask, render_template, request
from tensorflow.keras.models import load_model
#from sklearn.preprocessing import StandardScaler
import numpy as np
app = Flask(__name__)

@app.route('/',methods=['post','get']) # will use get for the first page-load, post for the form-submit
def predict(): # this function can have any name
    model = load_model('mymodel.h5') # the mymodel.h5 file was created in Colab, downloaded and uploaded using Filezilla
    in1 = request.form.get('in1') # get the two numbers from the request object
    in2 = request.form.get('in2')
    in3 = request.form.get('in3')
    if in1 == None or in2 == None or in3 == None: # check if any number is missing
        return render_template('index.html', result='No input(s)')
        # calling render_template will inject the variable 'result' and send index.html to the browser
    else:
        arr = np.array([[ float(in1),float(in2), float(in3) ]]) # cast string to decimal number, and make 2d numpy array.
        predictions = model.predict(arr) # make new prediction
        return render_template('index.html', result=str(predictions[0][0]))
        # the result is set, by asking for row=0, column=0. Then cast to string.

if __name__ == '__main__':
    app.run()
