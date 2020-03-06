from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, IntegerField
from wtforms.validators import DataRequired


class DataToFPGA(FlaskForm):
    start = IntegerField('Start Image', validators=[DataRequired()])
    end = IntegerField('End Image', validators=[DataRequired()])
    submit = SubmitField('Submit')