//
// Created by benjaminkulnik on 3/8/20.
//

#ifndef EGGNETDRIVER_CALLBACK_H
#define EGGNETDRIVER_CALLBACK_H

#include <iostream>


class Callback {
public:
    virtual ~Callback() { std::cout << "Callback::~Callback()" << std:: endl; }
    virtual void run() { std::cout << "Callback::run()" << std::endl; }
};

class Caller {
private:
    Callback *_callback;
public:
    Caller(): _callback(0) {}
    ~Caller() { delCallback(); }
    void delCallback() { delete _callback; _callback = 0; }
    void setCallback(Callback *cb) { delCallback(); _callback = cb; }
    void call() { if (_callback) _callback->run(); }
};


/**
 * A wrapper function to safely call the function from C
 */
extern "C" void run_callback(Callback* c);

#endif //EGGNETDRIVER_CALLBACK_H
