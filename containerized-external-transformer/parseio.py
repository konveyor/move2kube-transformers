# OM NAMO GANAPATHAYEN NAMAHA
#   Copyright IBM Corporation 2021
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
import sys
import os
import json
import yaml

# Parse I/O
def parseIO(ioEnvNames, printTag):
    args = sys.argv
    print('[' + printTag +']' + str(args))
    inputPath = ''
    outputPath = ''
    envInputName = ioEnvNames[0]
    envOutputName = ioEnvNames[1]
    if envInputName in os.environ:
        inputPath = os.environ[envInputName]
        print('[' + printTag + ' script] Input path in ENV: [' + inputPath + ']')
    else:
        for arg in args:
            if 'input=' in arg:
                tokens = arg.split("=")
                inputPath = tokens[1]
                break
    if envOutputName in os.environ:
        outputPath = os.environ[envOutputName]
        print('[' + printTag + ' script] Input path in ENV: [' + outputPath + ']')
    else:
        for arg in args:
            if 'output=' in arg:
                tokens = arg.split("=")
                outputPath = tokens[1]
                break
    return inputPath, outputPath