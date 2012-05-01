\documentclass[conference,10pt]{IEEEtran}
\IEEEoverridecommandlockouts

\usepackage{ifthen}
%include lineno.fmt
\input{preamble.dem}
%include waters2012.fmt

\begin{document}

\title{SoOSiM: System and \\ Programming Language Exploration}

\author{\IEEEauthorblockN{Christiaan Baaij\thanks{Supported through the S(o)OS project, sponsored by the European Commission under FP7-ICT-2009.8.1, Grant Agreement No. 248465}, Jan Kuper}
\IEEEauthorblockA{Computer Architecture for Embedded Systems\\
Department of EEMCS, University of Twente\\
Postbus 217, 7500AE Enschede, The Netherlands\\
Email: \url{{c.p.r.baaij;j.kuper}@@utwente.nl}}
}

\maketitle

\begin{abstract}
\boldmath
SoOSiM is a simulator developed for the purpose of exploring new operating system concepts and operating system modules.
The simulator provides a highly abstracted view of a computing system, consisting of computing nodes, and components that are concurrently executed on these nodes.
OS modules are subsequently modelled as components that progress as a result of reacting to two types of events: messages from other components, or a system-wide tick event.
Using this abstract view, a developer can quickly formalize assertions regarding the interaction between operating system modules and applications.

On top of SoOSiM a methodology was developed that allows the precise control of the interaction between simulated application and simulated operating system.
Embedded languages are used to model the application, and ad-hoc polymorphism is used to give different interpretations to the same application description.
The combination of SoOSim and embedded languages facilitates the exploration of new programming language concepts and their interaction with the operating system.
\end{abstract}

\section{Introduction}
Simulation is commonly used tool in the exploration of many design aspects of a system: ranging from feasibility aspects to gathering performance information.
However, when tasked with the creation of new operating system concepts, and their interaction with the programmability of large-scale systems, many simulation packages do not seem to have the right abstractions for fast exploration.
The work we present in this paper has been created in the context of the S(o)OS project\cite{soos}.
The S(o)OS project aims to research OS concepts and specific OS modules, that aid in scalability of the complete software stack (both OS and application) for future many-core systems.
One of the key concepts in S(o)OS is that only those OS modules needed by a thread are loaded into the (local) memory of a core/cpu on which the thread is executed.
This execution environment differs from contemporary OS' where every core runs a complete copy of the (monolithic) operating system.

A basic requirement that we have towards any simulator, is thus the ability to easily create application threads and OS modules.
Aside from the fact that the system will be dynamic as a result of loading OS modules on-the-fly; large-scale systems are also tend to be dynamic in the sense that computing nodes can (permanently) disappear, or even appear.
Hence, we also require that our simulator facilitates the straightforward creation and destruction of computing elements.
Our current needs for a simulator rest mostly in formalizing our ideas, and examining the interaction between OS modules and application threads.
As such, being able to extract highly accurate performance figures is not required.
We do however wish to be able to observe all interactions among applications threads and OS modules.
Additionally, we wish to be able to \emph{zoom in} on particular aspects of the behaviour of an application: such as memory access, messaging, etc.

This paper describes a new simulator, \emph{SoOSiM}, that meets the above requirements.
We elaborate on the main concepts of the simulator in Section~\ref{sec_soosim}, and show how OS modules interact with each other, and the simulator.
In Section~\ref{sec_embedded_programming_environment} we describe the use of embedded languages for creation of applications running in the simulated environment.
The simulation engine, the graphical user interface, and embedded language environment are all written in the functional programming language Haskell\cite{haskell98};
this means that all code listings in this paper will also show Haskell code.
We will compare \emph{SoOSiM} to other approaches in Section~\ref{sec_related_work}.
We enumerate our experiences with the simulator in Section~\ref{sec_conclusions}, and list potential future work in Section~\ref{sec_future_work}

\section{Abstract System Simulator}
\label{sec_soosim}
The purpose of SoOSiM is mainly to provide a platform that allows a developer to observe the interactions between OS modules and application threads.
It is for this reason that we have chosen to make the simulated hardware as abstract as possible.
In SoOSiM, the hardware platform is described as a set of nodes.
Each \emph{node} represents a physical computing object; such as a core, complete CPU, memory controller, etc.
Every node has a local memory of potentially infinite size.
The connectivity between nodes is not explicitly modelled.

Each \emph{node} hosts a set of components.
A \emph{components} represents an executable object; such as a thread, application, OS module, etc.
Components communicate with each other using either direct messaging, or through the local memory of a node.
Having both explicit messaging, and shared memories, SoOSiM supports the two well known methods of communication.
All components in a simulated system, even those hosted within the same node, are executed concurrently.
The simulator poses no restrictions on which components can communicate with each other, nor to which local memory they can read form and write to.
A user of SoOSiM would have to model those restrictions explicitly if required.
A schematic overview of example system can be seen in Figure~\ref{img_system}.

\def\svgwidth{\columnwidth}
\begin{figure}
\includesvg{system}
\caption{Abstracted System}
\label{img_system}
\end{figure}

As said earlier, components in the simulated system are executed concurrently, and communicate with each other through messaging.
Because multiple components can send messages to one component, all component have a message queue.
During one \emph{tick} of the simulator, all components will be executed concurrently, being passed the content that's at the head of the message queue.
If the message queue of a component is empty, a component will be executed with a \emph{null} message.
If required, a component can tell the simulator that it does not want to receive these \emph{null} messages.
When a component has no messages to process it will not be executed by the simulator.

\subsection{OS Component Descriptions}
Components of the simulated system are, like the simulator core, also described in the functional programming language Haskell.
This means that each component is described as a function.
In case of SoOSiM, such a function is not a simple algebraic function, but a function executed within the context of the simulator.
The Haskell parlance for this context is called a Monad, a concept originating from category theory.
Because the function is executed within the monadic context, it can have side-effects such as sending messages to other components, or reading the memory of a local memory.
In addition, the function can be temporarily suspended at (almost) any point in the code.
We need to be able to suspend the execution of a function so we can emulate synchronous messaging between components, a subject we will return to later.

We describe a component as a function that, as its first argument, receives a user-defined internal state, and as its second argument a value of type \hs{SimEvent}.
The result of this function will be the (potentially updated) internal state.
Values of type \hs{SimEvent} can either be:
\begin{itemize}
  \item A message from another component.
  \item A \emph{null} message.
\end{itemize}
We thus have the following type signature for a component:
\numbersoff
\begin{code}
component :: s -> SimEvent -> SimM s
\end{code}
The \hs{SimM} annotation means that this function is executed within the monadic context of the simulator.
The user-defined internal state can be used to store any information that needs to perpetuate across simulator ticks.
The simulator takes care that a component is executed with its unique local state every tick.

To include a component description in the simulator, the developer will have to create a so-called \emph{instance} of the \hs{ComponentIface} \emph{type-class}.
A \emph{type-class} in Haskell can be compared to an interface definition as those known in object-oriented languages.
An \emph{instance} of a \emph{type-class} is a concrete instantiation of such an interface.
The \hs{ComponentIface} requires the instantiation of the following values to completely define a component:
\begin{itemize}
  \item The initial internal state of the component.
  \item The unique name of the component.
  \item The monadic function describing the behaviour of the component.
\end{itemize}

\subsection{Interaction with the simulator}
Components have several functions at their disposal to interact with the simulator and consequently interact with other components.
All functions must be executed within the monadic context of the simulator.
The API is as follows:
\paragraph{\hs{registerComponent}}
Register a component definition with the simulator.
This means that an \emph{instance} of the \hs{CompIface} for this component must be defined.
\paragraph{\hs{createComponent}}
Instantiate a new component on a specified node; the component definition must be registered with the simulator.
\paragraph{\hs{invoke}}
Send a message to another component, and wait for the answer.
This means that whenever a component uses this function it will be (temporarily) suspended by the simulator.
Several simulator ticks might pass before before the callee sends a response.
Once the response is put in the message queue of the caller, the simulator resumes the execution of the calling component.
Having this synchronization available obviates the need to specify the behaviour of a component as a finite state machine.
\paragraph{\hs{invokeASync}}
Send a message to another component, and register a handler with the simulator to process the response.
Unlike \hs{invoke}, using this function will \hs{not} suspend the execution of the component.
\paragraph{\hs{respond}}
Send a message to another component as a response to an invocation.
\paragraph{\hs{yield}}
Inform the simulator that the component does not want to receive \emph{null} messages.
\paragraph{\hs{readMem}}
Read at a specified address of a node's local memory.
\paragraph{\hs{writeMem}}
Write a new value at a specified address of a node's local memory.
\paragraph{\hs{componentLookup}}
Lookup the the unique identifier for a component on a specified node.
Components have two unique identifiers, a global \emph{name} (as specified in the \hs{CompIface} instance), and a \hs{ComponentId} that is a unique number corresponding to a specific instance of a component.
When you want to \emph{invoke} a component, you need to know the unique \hs{ComponentId} of the specific instance.
To give a concrete example, using the system of Figure~\ref{img_system} as our context: \emph{Thread(2)} wants to invoke the instance of the \emph{Memory Manager} that is running on the same node (\#2).
As \hs{Thread(2)} was not involved with the instantiation of that OS module, it has no idea what the specific \hs{ComponentId} of the memory manager on node \#2 is.
It does however know the unique global name of all memory managers, so it can use the \hs{componentLookup} function to find the \hs{Memory Manager} with ID \#4 that is running on node \#2.

\subsection{Example OS Component: Memory Manager}
This subsection demonstrates the use of the simulator API, taking the \hs{Read} code-path of the memory manager OS module as an example.
In our case the memory manager takes care that the reads or writes of a global address end up in the correct node local memory.
As part of its internal state the memory manager keeps a lookup table.
This lookup table states whether an address range belongs to the local memory of the node that hosts the memory manager, or if that address is handled by a memory manager on another node.
An entry of the lookup table has the following datatype:
\begin{code}
data Entry = EntryC
  {  base   :: Int
  ,  range  :: Int
  ,  scrId  :: Maybe ComponentId
  }
\end{code}
The field \hs{base} and \hs{range} together describe the memory address range defined by this entry.
The \hs{srcId} tells whether the range is hosted on the node's local memory, or whether another memory manager is responsible for the address range.
If the value of \hs{scrId} is \hs{Nothing} the address is hosted on the node's local memory; if \hs{srcId} has the value \hs{Just cmpId}, the memory manager with ID \hs{cmpId} is responsible for the address range.

Listing~\ref{lst_read_logic_memory_manager} shows the Haskell code for the read-logic of the memory manager.
Lines 1 and 2 show the type signature of the function defining the behaviour of the memory manager.
On line 3 we use pattern-matching, to match on a \hs{Message} event, binding the values of the ComponentId of the caller, and the message content, to \hs{caller} and \hs{content} respectively.
Because components can send any type of message to the memory manager, including types we do not expect, we unmarshal the message content on line 4, and only continue if it is a \hs{Read} message.
If it is a \hs{Read} message, we bind the value of the address to the name \hs{addr}.
On line 6 we lookup the address range entry which encompasses \hs{addr}.
Line 7 starts a \hs{case}-statement discriminating on the value of the \hs{srcId} of the entry.
If the \hs{srcId} is \hs{Nothing} (line 8-11), we read the node's local memory using the \hs{readAddr} function, \hs{respond} to the caller with the read value, and finally \hs{yield} to the simulator.
When the address range is handled by a \hs{remote} memory manager (line 12-15), we \hs{invoke} that specific memory manager module with the read request and wait for a response.
Note that many simulator cycles might pass between the invocation and the return, as the \hs{remote} memory manager might be processing many requests.
Once we receive the value from the \hs{remote} memory manager, we \hs{respond} to the original caller forwarding the received value.
\begin{program}
\begin{code}
memoryManager :: MemState -> SimEvent
  -> SimM MemState
memoryManager s (Message caller content)
  | (Read addr) <- unMarshal content
  =  do
     let entry = addressLookup s addr
     case (srcId entry) of
       Nothing -> do
         addrVal <- readMemory addr
         respond caller addrVal
         yield s
       Just remote -> do
         response <- invoke remote content
         respond caller response
         yield s
\end{code}
\caption{Read logic of the Memory Manager}
\label{lst_read_logic_memory_manager}
\end{program}

\subsection{Simulator GUI}
The state of a simulated system can be observed using the SoOSiM GUI, of which a screen shot is depicted in Figure~\ref{fig_simulator_gui}.
The GUI allows you to run and step through a simulation at different speeds.
On the screen shot we see the toolbar controlling the simulation at the top, an overview of the simulated system in the middle, and specific information of a selected component at the bottom.
Different colours indicate whether a component is active, waiting for a response, or idle.
The \emph{Component Info} box shows static and statistical information regarding a selected component.
Several statistics are collected by the simulator, including the number of simulation cycles spend in a certain state (active / idle / waiting), messages send and received, etc.

These statistic can be used to roughly evaluate the performance bottlenecks in a system.
For example, when OS module 'A' has mostly active cycles, and components 'B'-'Z' are mostly waiting, one can check if components 'B'-'Z' were indeed communicating with 'A'.
If this happens to be the case, then 'A' is indeed a botteneck in the system.
A general indication of a well performing system is when OS modules have many \emph{idle} cycles, while application threads should have many \emph{active} cycles.
\begin{figure*}
\includegraphics[width=18cm]{images/gui.png}
\caption{Simulator GUI}
\label{fig_simulator_gui}
\end{figure*}

\section{Embedded Programming Environment}
\label{sec_embedded_programming_environment}
One of the reasons to develop SoOSiM is to observe the interaction between applications and operating system.
Additionally, we want to explore new programming language concepts intended for parallel and concurrent programming, and how they impact the operating system.
For this purpose we have developed a methodology on top of SoOSiM, that uses embedded languages to specify the application.
Our methodology consists of two important aspects:

\begin{itemize}
  \item The use of embedded (programming) languages to define an application.
  \item Defining different interpretations for such an application description, allowing a developer to observe different aspects of the execution of the application.
\end{itemize}

\subsection{Embedded Languages}
An embedded language is a language that can be used from within another language or application.
The language that is embedded is called the \emph{object} language, and the language in which is \emph{object} language is embedded is called the \emph{host} language.
Because the \emph{object} language is embedded, the \emph{host} language has complete control of any terms/expressions defined within this \emph{object} language.
There are multiple ways of representing embedded languages, for example as a string, which must subsequently be parsed within the \emph{host} language.

Haskell has been used to host many kinds of embedded (domain-specific) languages\cite{haskell_embedded}.
The standard approach in Haskell to not represent \emph{object} terms as strings, but instead use data-types and functions.
To make this idea more concrete, we present the recursive Fibbonaci function, defined using our self-defined \emph{embedded} functional language, in Listing~\ref{lst_fib}.

\begin{program}
%format fun = "\mathbf{fun}"
%format app = "\mathbf{app}"
%format fix = "\mathbf{fix}"
%format if_ = "\mathbf{if\_}"
%format lt  = "\mathbf{lt}"
%format drf = "\mathbf{drf}"
%format nv  = "\mathbf{nv}"
%format seq = "\mathbf{seq}"
%format `seq` = "\ `\mathbf{seq}`\ "
\begin{code}
fib :: Symantics repr => repr (IntT :-> IntT)
fib = fix $ \f ->
  fun $ \n ->
    nv 0 $ \n1 ->
    nv 0 $ \n2 ->
    nv 0 $ \n3 ->
      n1 =: n `seq`
      if_ (lt (drf n1) 2)
        1
        (  n2 =: (app f (drf n1 - 1)) `seq`
           n3 =: (app f (drf n1 - 2)) `seq`
           drf n2 + drf n3
        )
\end{code}
\caption{Call-by-Value Fibbonaci}
\label{lst_fib}
\end{program}

All functions printed in \textbf{bold} are language constructs in our \emph{embedded} language.
Additionally the \hs{=:} operator is also one of our \emph{embedded} language construct; the numeric operators and literals are also overloaded to represent embedded terms.
To give some insight as to how Listing~\ref{lst_fib} represents the recursive Fibbonaci function, we quickly elaborate each of the lines.

The type annotation on line 1 tells us that we have an function defined at the \emph{object}-level with an \emph{object}-level integer as argument and an \emph{object}-level integer as result.
Line 2 creates a fixed-point over \hs{f}, making the recursion of our embedded Fibbonaci function explicit.
On line 3 we define a function parameter \hs{n} using the \hs{fun} construct.
Note that we use Haskell binders to represent binders in our \emph{embedded} language.
On line 4-6 we introduce three mutable references, all having the initial integer value of 0.
We assign the value of \hs{n} to the mutable reference \hs{n1} on line 7.
On line 8 we check if the derefenced value of \hs{n1} is less than 2; if so we return 1 (line 9); otherwise we assign the value of the recursive call of \hs{f} with \hs{(n1 - 1)} to \hs{n2}, and assign the value of the recursive call of \hs{f} with \hs{(n1 - 2)} to \hs{n3}.
We subsequently return the addition of the dereferenced variables \hs{n2} and \hs{n3}.

We must confess that there is some syntactic overhead as a result of using Haskell functions and datatypes to specify the language constructs of our \emph{embedded} language; as opposed to using a string representation.
However, we have consequently saved ourselves from many implementation burdens associated with embedded languages:
\begin{itemize}
  \item We do not have to create a parser for our language.
  \item We can use Haskell bindings to represent bindings in our own language, avoiding the need to deal with such 'tricky' concepts as free variables and capture-free substitution.
  \item We can use Haskell's type system to represent types in our embedded language: meaning we can use Haskell's type-checker to check expressions defined in our own embedded language.
\end{itemize}

\subsection{Interpreting an Embedded Language}
We mentioned the concept of \emph{type-classes} when we discussed how to include a component description in the simulator.
Following the \emph{final tagless}\cite{final_tagless_embedding} encoding of embedded languages in Haskell, we use a type-class to define the language constructs of our mini functional language with mutable references.
A partial specification of the \hs{Symantics} (a pun on \emph{syntax} and \emph{semantics}) type-class, defining our \emph{embedded language}, is shown in Listing~\ref{lst_embedded_language_interface}.

\begin{program}
\begin{code}
class Symantics repr where
  fun  :: (repr a -> repr b) -> repr (a :-> b)
  app  :: repr (a :-> b) -> repr a -> repr b
\end{code}
$\ \ \ .\ .\ .$
\begin{code}
^^ drf   :: repr (Ref a) -> repr a
^^ (=:)  :: repr (Ref a) -> repr a -> repr Void
\end{code}
\caption{Embedded Language - Partial Definition}
\label{lst_embedded_language_interface}
\end{program}

We read the types of our language definition constructs as follows:
\begin{itemize}
  \item \hs{fun} takes a \emph{host}-level function from \hs{object}-type \hs{a} to \hs{object}-type \hs{b}, and returns an \emph{object}-level function from \hs{a} to \hs{b}.
  \item \hs{app} takes an \emph{object}-level function from \hs{a} to \hs{b}, and applies this function to an \emph{object}-term of type \hs{a}, returning an \emph{object}-term of type \hs{b}.
  \item \hs{drf} dereferences an \hs{object}-term of type "reference of" \hs{a}, returning an \emph{object}-term of type \hs{a}.
  \item \hs{(=:)} is operator that updates an \emph{object}-term of type "reference of" \hs{a}, with a new \emph{object}-value of type \hs{a}, returning an \emph{object}-term of type \hs{Void}.
\end{itemize}

To give a desired interpretation of an application described in our embedded language we simply have to implement an instance of the \hs{Symantics} type-class.
These interpretations include pretty-printing the description, determining the size of expression, evaluating the description as if it were a normal Haskell function, etc.

In the context of this paper we are however interested in \emph{observing} (specific parts of) the execution of an application described in our newly created embedded language.
As a running example, we show part of an instance definition that observes the invocations of the memory manager upon dereferencing and updating mutable references:

\begin{program}
\begin{code}
newtype MemAccess = M { unM :: SimM }

instance Symantics MemAccess where
  ...

  drf x = M $ do
    i     <- ...  x  ...
    mmId  <- componentLookup "MemoryManager"
    invoke mmId (marshal (Read i))

  x =: y = M $ do
    i     <- ...  x  ...
    v     <- ...  y  ...
    mmId  <- componentLookup "MemoryManager"
    invoke mmId (mashal (Write i v))
\end{code}
\caption{Observing Memory Access}
\label{lst_observing_memory_access}
\end{program}

\section{Related Work}
\label{sec_related_work}

\section{Conclusions}
\label{sec_conclusions}

\section{Future Work}
\label{sec_future_work}

\section*{Acknowledgements}
The authors would like to thank Ivan Perez for the design and implementation of the SoOSiM GUI.

\bibliographystyle{IEEEtran}
\bibliography{waters2012}

\end{document}


