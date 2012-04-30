\documentclass[conference,10pt]{IEEEtran}
\IEEEoverridecommandlockouts

\usepackage{ifthen}
%include lineno.fmt
\input{preamble.dem}
%include waters2012.fmt

\begin{document}

\title{SoOSiM: System and Programming Language Exploration}

\author{\IEEEauthorblockN{Christiaan Baaij\thanks{Supported through the S(o)OS project, sponsored by the European Commission under FP7-ICT-2009.8.1, Grant Agreement No. 248465}, Jan Kuper}
\IEEEauthorblockA{Computer Architecture for Embedded Systems\\
Department of EEMCS, University of Twente\\
Postbus 217, 7500AE Enschede, The Netherlands\\
Email: \url{{c.p.r.baaij;j.kuper}@@utwente.nl}}
}

\maketitle

\begin{abstract}
\boldmath
SoOSiM is a simulator developed for the purpose of exploration of new operating system concepts and operating system modules.
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
The simulation engine, the graphical user interface, and embedded language environment are all written in the functional programming language Haskell\cite{Haskell};
this means that all code listings in this paper will also show Haskell code.
We will compare \emph{SoOSiM} to other approaches in Section~\ref{sec_related_work}.
We enumerate our experiences with the simulator in Section~\ref{sec_conclusions}, and list potential future work in Section~\ref{sec_future_work}

\section{An Abstracted System View}
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
If required, a component can tell the simulator that it does not want to receive these \emph{null} messages; meaning that the component will not be executed for those simulator ticks when its message queue is empty.

\subsection{OS Component Descriptions}
Components of the simulated system are, like the simulator core, also described in the functional language Haskell.
This means that each component is described as a function.
In case of SoOSiM, such a function is not a simple algebraic function, but a function executed within the context of the simulator.
The Haskell parlance for this context is called a Monad, a concept originating from category theory.
Because the function is executed within the monadic context, it can have side-effects such as sending messages to other components, or reading the memory the local memory.
In addition, the function can be temporarily suspended at (almost) any point in the code.
We need to be able to suspend the execution of a function so we can emulate synchronous messaging between components.

We describe a component as a function that, as its first argument, receives a user-defined internal state, and as its second argument a value of type \hs{SimEvent}.
The result of this function will be the (potentially updated) internal state.
We thus have the following type signature for a component:
\begin{code}
component :: s -> SimEvent -> SimM s
\end{code}
The \hs{SimM} annotation means that this function is executed within the monadic context of the simulator.

% Components have several functions at their disposal to communicate with the simulator:
% \begin{itemize}
%   \item \textbf{CreateNode:} Creating a new computing node.
%   \item \textbf{CreateComponent:} Instantiate a component on a specified node.
%   \item \textbf{Invoke:} Send a message to another component, and wait for the answer.
%   \item \textbf{InvokeAsync:} Send a message to another component, and register a callback to handle the response.
%   \item \textbf{ReadMem:} Read the memory of a specified node.
%   \item \textbf{WriteMem:} Write the memory of a specified node.
%   \item \textbf{ComponentLookup:} Lookup the the unique component identifier on a specified node.
% \end{itemize}

\section{Embedded Programming Environment}
\label{sec_embedded_programming_environment}

\begin{program}
\begin{code}
class Symantics repr where
  fun   :: (repr a -> repr b) -> repr (a :-> b)
  app   :: repr (a :-> b) -> repr a -> repr b
  fix   :: (repr a -> repr a) -> repr a

  int   :: repr Int -> repr IntT
  sub   :: repr IntT -> repr IntT -> repr IntT

  if_   :: repr BoolT -> repr a -> repr a -> repr a
  lt    :: repr IntT -> repr IntT -> repr BoolT

  ref   :: repr a -> repr (Ref a)
  drf   :: repr (Ref a)
  (=:)  :: repr (Ref a) -> exp a -> exp Void
  seq   :: repr a -> repr b -> repr b
\end{code}
\caption{Embedded language interface}
\label{lst:genpredfunc}
\end{program}


\begin{program}
%format fun = "\mathbf{fun}"
%format app = "\mathbf{app}"
%format fix = "\mathbf{fix}"
%format if_ = "\mathbf{if\_}"
%format lt  = "\mathbf{lt}"
%format drf = "\mathbf{drf}"
%format seq = "\mathbf{seq}"
%format `seq` = "\ `\mathbf{seq}`\ "
\begin{code}
fib :: repr (IntT :-> IntT)
fib = fix $ \f ->
  fun $ \n ->
    newvar 0 $ \n1 ->
    newvar 0 $ \n2 ->
    newvar 0 $ \n3 ->
      n1 =: n `seq`
      if_ (lt (drf n1) 2)
        1
        (  n2 =: (app f (drf n1 - 1)) `seq`
           n3 =: (app f (drf n1 - 2)) `seq`
           drf n2 + drf n3
        )
\end{code}
\caption{Call-by-Value Fibbonaci}
\label{lst:fib}
\end{program}

\section{Related Work}
\label{sec_related_work}
CλaSH\cite{eemcs18376}.

\section{Conclusions}
\label{sec_conclusions}

\section{Future Work}
\label{sec_future_work}

\bibliographystyle{IEEEtran}
\bibliography{waters2012}

\end{document}
