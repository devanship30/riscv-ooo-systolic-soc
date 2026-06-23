// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vpe_tb.h for the primary calling header

#ifndef VERILATED_VPE_TB___024ROOT_H_
#define VERILATED_VPE_TB___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vpe_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vpe_tb___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ pe_tb__DOT__clk;
    CData/*0:0*/ pe_tb__DOT__rst_n;
    CData/*0:0*/ pe_tb__DOT__load_en;
    CData/*7:0*/ pe_tb__DOT__in_left;
    CData/*7:0*/ pe_tb__DOT__out_right;
    CData/*7:0*/ pe_tb__DOT__uut__DOT__weight_reg;
    CData/*0:0*/ __Vdlyvval__pe_tb__DOT__clk__v0;
    CData/*0:0*/ __Vdlyvset__pe_tb__DOT__clk__v0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__pe_tb__DOT__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__pe_tb__DOT__rst_n__0;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ pe_tb__DOT__in_top;
    IData/*31:0*/ pe_tb__DOT__out_bottom;
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<CData/*0:0*/, 2> __Vm_traceActivity;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h0332e823__0;
    VlTriggerVec<3> __VactTriggered;
    VlTriggerVec<3> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vpe_tb__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vpe_tb___024root(Vpe_tb__Syms* symsp, const char* v__name);
    ~Vpe_tb___024root();
    VL_UNCOPYABLE(Vpe_tb___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
