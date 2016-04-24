//
//  Network.m
//  NN
//
//  Created by 杨培文 on 16/4/19.
//  Copyright © 2016年 杨培文. All rights reserved.
//

#import "Network.h"


Network::Network(int ns[], int ls, ActivationFunction activation, RegularizationFunction regularzation) {
    //    int numLayers = (int)networkShape.size();
    Activation act;
    Regularization reg;
    switch (activation) {
        case ReLU:
            act.output = aReLU;
            act.der = aderReLU;
            break;
        case Tanh:
            act.output = aTanh;
            act.der = aderTanh;
            break;
        case Sigmoid:
            act.output = aSigmoid;
            act.der = aderSigmoid;
            break;
        case Linear:
            act.output = aLinear;
            act.der = aderLinear;
            break;
        default:
            break;
    }
    
    switch (regularzation) {
        case None:
            reg.output = rNone;
            reg.der = rNone;
            break;
        case L1:
            reg.output = rL1;
            reg.der = rderL1;
            break;
        case L2:
            reg.output = rL2;
            reg.der = rderL2;
            break;
        default:
            break;
    }
    
    numLayers = ls;
    for(int i = 0; i < numLayers; i++){
        networkShape.push_back(ns[i]);
    }
    
    /** List of layers, with each layer being a list of nodes. */
    for (int layerIdx = 0; layerIdx < numLayers; layerIdx++) {
        vector<Node*>* currentLayer = new vector<Node*>();
        for (int i = 0; i < networkShape[layerIdx]; i++) {
            auto node = new Node(act);
            node->layer = layerIdx + 1; //tag this node
            node->id = i + 1;
            node->outputBitmap = new unsigned int[node->imageWidth * node->imageWidth];
            node->imageBytes = 4 * node->imageWidth * node->imageWidth;
            if (layerIdx >= 1) {
                // Add links from nodes in the previous layer to this node.
                for (int j = 0; j < network[layerIdx - 1]->size(); j++) {
                    Node * prevNode = (*network[layerIdx - 1])[j];
                    auto link = new Link(prevNode, node, reg);
                    prevNode->outputs.push_back(link);
                    node->inputLinks.push_back(link);
                }
            }
            currentLayer->push_back(node);
        }
        network.push_back(currentLayer);
    }
}

Network::~Network(){
    for (int i = 0; i < numLayers; i++) {
        auto currentLayer = *network[i];
        for(int j = 0; j < networkShape[i]; j++){
            //delete every node
            delete(currentLayer[j]);
        }
    }
    for (int i = 0; i < numLayers; i++) {
        //delete every layer
        delete(network[i]);
    }
}

double Network::forwardProp(double inputs[], int inputSize) {
    vector<Node*> &inputLayer = *network[0];
    if (inputSize != inputLayer.size()) {
        printf("The number of inputs must match the number of nodes in the input layer!\n");
        return -1;
    }
    
    // Update the input layer.
    for (int i = 0; i < inputLayer.size(); i++) {
        inputLayer[i]->output = inputs[i];
    }
    
    for (int layerIdx = 1; layerIdx < network.size(); layerIdx++) {
        // Update all the nodes in this layer.
        vector<Node*> &currentLayer = *network[layerIdx];
        for (int i = 0; i < currentLayer.size(); i++) {
            currentLayer[i]->updateOutput();
        }
    }
    return (*network[network.size() - 1])[0]->output;
}

double Network::forwardProp(double inputs[], int inputSize, int x1, int x2) {
    vector<Node*> &inputLayer = *network[0];
    if (inputSize != inputLayer.size()) {
        printf("The number of inputs must match the number of nodes in the input layer!\n");
        return -1;
    }
    
    // Update the input layer.
    for (int i = 0; i < inputLayer.size(); i++) {
        inputLayer[i]->output = inputs[i];
    }
    
    for (int layerIdx = 1; layerIdx < network.size(); layerIdx++) {
        // Update all the nodes in this layer.
        vector<Node*> &currentLayer = *network[layerIdx];
        for (int i = 0; i < currentLayer.size(); i++) {
            currentLayer[i]->updateOutput(x1, x2);
        }
    }
    return (*network[network.size() - 1])[0]->output;
}

void Network::backProp(double target) {
    // The output node is a special case. We use the user-defined error
    // function for the derivative.
    vector<Node*> &lastLayer = *network[network.size() - 1];
    auto outputNode = lastLayer[0];
    outputNode->outputDer = outputNode->output - target;
    
    // Go through the layers backwards.
    for (auto layerIdx = network.size() - 1; layerIdx >= 1; layerIdx--) {
        vector<Node*> &currentLayer = *network[layerIdx];
        // Compute the error derivative of each node with respect to:
        // 1) its total input
        // 2) each of its input weights.
        for (int i = 0; i < currentLayer.size(); i++) {
            auto node = currentLayer[i];
            node->inputDer = node->outputDer * node->activation.der(node->totalInput);
            node->accInputDer += node->inputDer;
            node->numAccumulatedDers++;
        }
        
        // Error derivative with respect to each weight coming into the node.
        for (int i = 0; i < currentLayer.size(); i++) {
            auto node = currentLayer[i];
            for (int j = 0; j < node->inputLinks.size(); j++) {
                auto link = node->inputLinks[j];
                link->errorDer = node->inputDer * link->source->output;
                link->accErrorDer += link->errorDer;
                link->numAccumulatedDers++;
            }
        }
        if (layerIdx == 1) {
            continue;
        }
        
        vector<Node*> &prevLayer = *network[layerIdx - 1];
        for (int i = 0; i < prevLayer.size(); i++) {
            auto node = prevLayer[i];
            // Compute the error derivative with respect to each node's output.
            node->outputDer = 0;
            for (int j = 0; j < node->outputs.size(); j++) {
                auto output = node->outputs[j];
                node->outputDer += output->weight * output->dest->inputDer;
            }
        }
    }
}

void Network::updateWeights(double learningRate, double regularizationRate) {
    for (int layerIdx = 1; layerIdx < network.size(); layerIdx++) {
        vector<Node*> &currentLayer = *network[layerIdx];
        for (int i = 0; i < currentLayer.size(); i++) {
            auto node = currentLayer[i];
            // Update the node's bias.
            if (node->numAccumulatedDers > 0) {
                node->bias -= learningRate * node->accInputDer / node->numAccumulatedDers;
                node->accInputDer = 0;
                node->numAccumulatedDers = 0;
            }
            // Update the weights coming into this node.
            for (int j = 0; j < node->inputLinks.size(); j++) {
                auto link = node->inputLinks[j];
                auto regulDer = link->regularization.der(link->weight);
                if (link->numAccumulatedDers > 0) {
                    link->weight -= (learningRate / link->numAccumulatedDers) *
                    (link->accErrorDer + regularizationRate * regulDer);
                    link->accErrorDer = 0;
                    link->numAccumulatedDers = 0;
                }
            }
        }
    }
}

void Network::forEachNode(bool ignoreInputs, void (*accessor)(Node*) ){
    for (int layerIdx = ignoreInputs ? 1 : 0; layerIdx < network.size(); layerIdx++) {
        vector<Node*> & currentLayer = *network[layerIdx];
        for (int i = 0; i < currentLayer.size(); i++) {
            accessor(currentLayer[i]);
        }
    }
}

Node* Network::getOutputNode(){
    return (*network[network.size()-1])[0];
}
