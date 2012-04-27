\documentclass[conference,10pt]{IEEEtran}
\IEEEoverridecommandlockouts

\usepackage{ifthen}
%include lineno.fmt
\input{preamble.dem}
%include waters2012.fmt

\begin{document}

\title{PANACEA - Functional System Design Space Exploration}

\author{\IEEEauthorblockN{Christiaan Baaij\thanks{Supported through the S(o)OS project, sponsored by the European Commission under FP7-ICT-2009.8.1, Grant Agreement No. 248465}, Jan Kuper}
\IEEEauthorblockA{Computer Architecture for Embedded Systems\\
Department of EEMCS, University of Twente\\
Postbus 217, 7500AE Enschede, The Netherlands\\
Email: \url{{c.p.r.baaij;j.kuper}@@utwente.nl}}
}

\maketitle

\begin{abstract}
\boldmath
To offer the panacea for complete system design space exploration, from hardware, over the OS, to applications.
To put an end to crappy 6-core, 2-router NoC/SoC examples --- where a fully-connected point-to-point architecture would work better --- found in accepted papers at `respected' conferences.
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
Additionally, we wish to be able to 'zoom in' on particular aspects of the behaviour of an application: such as memory access, messaging, etc.

% Additionally, our simulation needs mostly rest on testing and formalizing the ideas of our OS concepts, and not so much on measuring exact performance.
% Although there is still a need to get an insight how our OS concepts and modules scale, exact cycle counts are certainly not required.


\section{Abstracted System}
There are two basic entities in our abstract view of a system:
\begin{itemize}
  \item \textbf{Nodes:} Representing a physical computing object; such as a core, complete CPU, router, memory controller, etc.
  \item \textbf{Components:} Representing an execution object; such as a thread, application, OS module, etc.
\end{itemize}
A system consists of a set of \emph{nodes}, each hosting their own set of \emph{components}.
Every \emph{node} has a local internal \emph{memory} which can be accessed by both local and remote components.
All components on a node are executed concurrently, and all nodes are executed concurrently with respect to eachother.
Components can communicate using either direct messaging, or through the local memory of a node.

\section{Simulation API}
Components have several functions at their disposal to communicate with the simulator:
\begin{itemize}
  \item \textbf{CreateNode:} Creating a new computing node.
  \item \textbf{CreateComponent:} Instantiate a component on a specified node.
  \item \textbf{Invoke:} Send a message to another component, and wait for the answer.
  \item \textbf{InvokeAsync:} Send a message to another component, and register a callback to handle the response.
  \item \textbf{ReadMem:} Read the memory of a specified node.
  \item \textbf{WriteMem:} Write the memory of a specified node.
  \item \textbf{ComponentLookup:} Lookup the the unique component identifier on a specified node.
\end{itemize}

\section{Embedded Programming Environment}


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
CλaSH\cite{eemcs18376}.

\section{Conclusions}

\section{Future Work}

\bibliographystyle{IEEEtran}
\bibliography{waters2012}

\end{document}
