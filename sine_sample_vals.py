# This Python script generates the 128 PWM samples that define
# the sine wave produced by the FPGA

import math
import matplotlib.pyplot as plt

NUM_SAMPLES = 128
MAX_PWM = 255

sine_sample_vals = []

for x in range(NUM_SAMPLES):
    phase = (2 * math.pi * x) / NUM_SAMPLES
    sample_value = int(MAX_PWM * ((math.sin(phase) + 1) / 2))
    sine_sample_vals.append(sample_value)

plt.figure()
plt.plot(sine_sample_vals)
plt.xlabel("Sample index")
plt.ylabel("PWM value")
plt.title("128-sample PWM sine wave")
plt.grid(True)
plt.show()




    