#!/bin/bash

swift-format lint ../Sources ../Tests --recursive --parallel --strict --configuration ../.swift-format
