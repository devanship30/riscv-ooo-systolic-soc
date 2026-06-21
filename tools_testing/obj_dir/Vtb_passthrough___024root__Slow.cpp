// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_passthrough.h for the primary calling header

#include "Vtb_passthrough__pch.h"
#include "Vtb_passthrough__Syms.h"
#include "Vtb_passthrough___024root.h"

void Vtb_passthrough___024root___ctor_var_reset(Vtb_passthrough___024root* vlSelf);

Vtb_passthrough___024root::Vtb_passthrough___024root(Vtb_passthrough__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , __VdlySched{*symsp->_vm_contextp__}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vtb_passthrough___024root___ctor_var_reset(this);
}

void Vtb_passthrough___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

Vtb_passthrough___024root::~Vtb_passthrough___024root() {
}
