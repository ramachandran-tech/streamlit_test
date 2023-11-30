from fastapi import FastAPI
from pydantic import BaseModel
from typing import Union

class user_input(BaseModel):
	value1: int
	value2: int

app = FastAPI()

@app.post('/add')
def add(input: user_input):
	return f"The added result is: {input.value1+input.value2}"

@app.post('/subtract')
def subtract(input: user_input):
	return f"The subtrated result is: {input.value1-input.value2}"

@app.post('/multiply')
def subtract(input: user_input):
	return f"The multiplied result is: {input.value1*input.value2}"

@app.post('/divide')
def divide(input: user_input):
	return f"The divided result is: {input.value1/input.value2}"