// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vpe_tb__pch.h"
#include "verilated_vcd_c.h"

//============================================================
// Constructors

Vpe_tb::Vpe_tb(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vpe_tb__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vpe_tb::Vpe_tb(const char* _vcname__)
    : Vpe_tb(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vpe_tb::~Vpe_tb() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vpe_tb___024root___eval_debug_assertions(Vpe_tb___024root* vlSelf);
#endif  // VL_DEBUG
void Vpe_tb___024root___eval_static(Vpe_tb___024root* vlSelf);
void Vpe_tb___024root___eval_initial(Vpe_tb___024root* vlSelf);
void Vpe_tb___024root___eval_settle(Vpe_tb___024root* vlSelf);
void Vpe_tb___024root___eval(Vpe_tb___024root* vlSelf);

void Vpe_tb::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vpe_tb::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vpe_tb___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_activity = true;
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vpe_tb___024root___eval_static(&(vlSymsp->TOP));
        Vpe_tb___024root___eval_initial(&(vlSymsp->TOP));
        Vpe_tb___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vpe_tb___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

void Vpe_tb::eval_end_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+eval_end_step Vpe_tb::eval_end_step\n"); );
#ifdef VM_TRACE
    // Tracing
    if (VL_UNLIKELY(vlSymsp->__Vm_dumping)) vlSymsp->_traceDump();
#endif  // VM_TRACE
}

//============================================================
// Events and timing
bool Vpe_tb::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Vpe_tb::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vpe_tb::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vpe_tb___024root___eval_final(Vpe_tb___024root* vlSelf);

VL_ATTR_COLD void Vpe_tb::final() {
    Vpe_tb___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vpe_tb::hierName() const { return vlSymsp->name(); }
const char* Vpe_tb::modelName() const { return "Vpe_tb"; }
unsigned Vpe_tb::threads() const { return 1; }
void Vpe_tb::prepareClone() const { contextp()->prepareClone(); }
void Vpe_tb::atClone() const {
    contextp()->threadPoolpOnClone();
}
std::unique_ptr<VerilatedTraceConfig> Vpe_tb::traceConfig() const {
    return std::unique_ptr<VerilatedTraceConfig>{new VerilatedTraceConfig{false, false, false}};
};

//============================================================
// Trace configuration

void Vpe_tb___024root__trace_decl_types(VerilatedVcd* tracep);

void Vpe_tb___024root__trace_init_top(Vpe_tb___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD static void trace_init(void* voidSelf, VerilatedVcd* tracep, uint32_t code) {
    // Callback from tracep->open()
    Vpe_tb___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vpe_tb___024root*>(voidSelf);
    Vpe_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (!vlSymsp->_vm_contextp__->calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
            "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->pushPrefix(std::string{vlSymsp->name()}, VerilatedTracePrefixType::SCOPE_MODULE);
    Vpe_tb___024root__trace_decl_types(tracep);
    Vpe_tb___024root__trace_init_top(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void Vpe_tb___024root__trace_register(Vpe_tb___024root* vlSelf, VerilatedVcd* tracep);

VL_ATTR_COLD void Vpe_tb::trace(VerilatedVcdC* tfp, int levels, int options) {
    if (tfp->isOpen()) {
        vl_fatal(__FILE__, __LINE__, __FILE__,"'Vpe_tb::trace()' shall not be called after 'VerilatedVcdC::open()'.");
    }
    if (false && levels && options) {}  // Prevent unused
    tfp->spTrace()->addModel(this);
    tfp->spTrace()->addInitCb(&trace_init, &(vlSymsp->TOP));
    Vpe_tb___024root__trace_register(&(vlSymsp->TOP), tfp->spTrace());
}
