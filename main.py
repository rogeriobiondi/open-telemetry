import os
from random import randint
from typing import Union

from art import text2art
from fastapi import FastAPI
from opentelemetry import metrics, trace

app = FastAPI()

# Create a tracer and meter
tracer = trace.get_tracer("diceroller.tracer")
meter  = metrics.get_meter("diceroller.meter")
roll_counter = meter.create_counter("roll_counter", description="Number of rools by roll value")
OTEL_SERVICE_NAME = os.getenv('OTEL_SERVICE_NAME')

@app.get("/")
def read_root():
    return {"status": "online"}

@app.get("/roll_dice")
def roll_dice(dice: int = 1, faces: int = 6):
    dice_result = []
    for dye in range(0, dice): 
        dice_result.append({ 
            "dye": (dye + 1), 
            "result": do_roll()
        })
    return dice_result

def do_roll(faces: int = 6) -> int:
    # Add the roll.value metric
    with tracer.start_as_current_span("do_roll") as rollspan:
        result = randint(1, faces)
        rollspan.set_attribute("roll.value", result)
        roll_counter.add(1, {"roll.value": result})
        return result

print(text2art("otel-api"))
print(f"Monitoring {OTEL_SERVICE_NAME} service...")

