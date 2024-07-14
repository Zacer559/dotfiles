import argparse
import time

import pynvml


def set_fan_speed_based_on_temp(
    gpu_handle, temp, min_temp, min_speed, max_temp, max_speed
):
    """
    Calculate and set the fan speed based on the given temperature using the provided curve:
    min_temp -> min_speed%
    max_temp -> max_speed%
    """
    if temp <= min_temp:
        fan_speed = min_speed
    elif temp >= max_temp:
        fan_speed = max_speed
    else:
        # Linear interpolation between min_temp and max_temp
        fan_speed = min_speed + (temp - min_temp) * (
            (max_speed - min_speed) / (max_temp - min_temp)
        )

    fan_speed = int(fan_speed)
    # Set the fan speed
    fan_count = pynvml.nvmlDeviceGetNumFans(gpu_handle)
    for fan_idx in range(fan_count):
        pynvml.nvmlDeviceSetFanSpeed_v2(gpu_handle, fan_idx, fan_speed)

    # Get the actual fan speeds
    actual_fan_speeds = []
    for fan_idx in range(fan_count):
        actual_speed = pynvml.nvmlDeviceGetFanSpeed_v2(gpu_handle, fan_idx)
        actual_fan_speeds.append(actual_speed)

    return actual_fan_speeds


def log_fan_speed(file_path, fan_speed):
    with open(file_path, "w") as log_file:
        log_file.write(f"{fan_speed}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Set GPU fan speed based on temperature."
    )
    parser.add_argument("--gpu_name", type=str, required=True, help="Name of the GPU")
    parser.add_argument(
        "--min_temp",
        type=int,
        required=True,
        help="Minimum temperature for fan speed control",
    )
    parser.add_argument(
        "--min_speed",
        type=int,
        required=True,
        help="Fan speed at minimum temperature (in %)",
    )
    parser.add_argument(
        "--max_temp",
        type=int,
        required=True,
        help="Maximum temperature for fan speed control",
    )
    parser.add_argument(
        "--max_speed",
        type=int,
        required=True,
        help="Fan speed at maximum temperature (in %)",
    )
    parser.add_argument(
        "--interval",
        type=int,
        required=True,
        help="Time interval between checks (in seconds)",
    )
    parser.add_argument(
        "--log_file", type=str, required=True, help="File to log the actual fan speed"
    )

    args = parser.parse_args()

    pynvml.nvmlInit()

    # Find the GPU by name
    device_count = pynvml.nvmlDeviceGetCount()
    gpu_handle = None

    for i in range(device_count):
        handle = pynvml.nvmlDeviceGetHandleByIndex(i)
        name = pynvml.nvmlDeviceGetName(handle)
        if args.gpu_name in str(name):
            gpu_handle = handle
            break

    if gpu_handle is None:
        pynvml.nvmlShutdown()
        return

    try:
        while True:
            # Get the current temperature
            temp = pynvml.nvmlDeviceGetTemperature(
                gpu_handle, pynvml.NVML_TEMPERATURE_GPU
            )
            actual_fan_speeds = set_fan_speed_based_on_temp(
                gpu_handle,
                temp,
                args.min_temp,
                args.min_speed,
                args.max_temp,
                args.max_speed,
            )

            # Log the last fan speed to a file
            log_fan_speed(args.log_file, actual_fan_speeds[-1])

            # Sleep for the specified interval before checking again
            time.sleep(args.interval)

    except KeyboardInterrupt:
        pass

    pynvml.nvmlShutdown()


if __name__ == "__main__":
    main()
