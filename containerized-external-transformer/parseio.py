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
    inputPath = ''
    outputPath = ''
    if len(sys.argv) < 3:
            print(printTag + ' Input/Output path not specified in script CLI...checking environment variables')
            if ioEnvNames[0] in os.environ:
                inputPath = os.environ[ioEnvNames[0]]
                print(printTag + ' Input path received from environment variable')
            else:
                print(printTag + ' Input path not specified in environment as well')
                exit(0)
            if ioEnvNames[1] in os.environ:
                outputPath = os.environ[ioEnvNames[1]]
                print(printTag + ' Output path received from environment variable')
            else:
                print(printTag + ' Output path not specified in environment as well')
                exit(0)
    else:
        for arg in sys.argv:
            if 'input=' in arg:
                tokens = arg.split("=")
                inputPath = tokens[1]
            if 'output=' in arg:
                tokens = arg.split("=")
                outputPath = tokens[1]
        print('%s Input path: [%s], Output path: [%s]. Data received from CLI' % (printTag, inputPath, outputPath))
    if len(inputPath) == 0 or len(outputPath) == 0:
        print(printTag + ' Input/Output path not specified in script cli as well')
        exit(0)
    return inputPath, outputPath