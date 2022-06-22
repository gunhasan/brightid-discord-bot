module FaBars = {
  @react.component @module("react-icons/fa")
  external make: unit => React.element = "FaBars"
}

@react.component
let make = (~handleToggleSidebar) => {
  <div
    className="md:hidden cursor-pointer w-12 h-12 bg-dark text-center text-white rounded-full flex justify-center items-center font-xl"
    onClick={_ => handleToggleSidebar(true)}>
    <FaBars />
  </div>
}