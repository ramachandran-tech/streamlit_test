import streamlit as st
import json
import requests

st.title("Test streamlit calculator app")

option = st.selectbox("what operation do you want to perform?", ('add', 'subtract', 'multiply', 'divide'))
st.write("")
st.write("select numbers from the slider below")

v1 = st.slider("value1", 0, 100, 20)
v2 = st.slider("value2", 0, 100, 10)

inputs = {"value1": v1, "value2": v2}
print(inputs)
calc_operation = option
if st.button("Calculate"):
	res = requests.post(url=f'http://localhost:8000/{calc_operation}', data = json.dumps(inputs))

	st.subheader(f"Response from API = {res.text}")
