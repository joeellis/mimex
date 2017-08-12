# Mimex

Mimex is an Elixir library to help automate the creation and implementation of module doubles for testing. It's most useful when testing controllers in apps that use a service-oriented architecture as service often need to be mocked in order to fully test each possible code path.

Mimex aims to solve this by offering the these features:
- Automate the creation of mock doubles. No need to keep separate files for mocks or constantly keep definition up to date, `Mimex.stub(Foo)` can read a given module and return back a module with the same functions / arities as the original.
- Change the implementation of module functions on the fly at the test level. Keep everything needed for a test to run in the same place.


## Installation

Simply install the package by adding `mimex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:mimex, "~> 0.1.0"}]
end
```

## Usage

```elixir

# config.exs
config :app, :user_service, UserService

# user_service.ex
defmodule UserService do
  def create_user(params) do
    # do things involved with creating a user
    ...

    {:ok, user}
  end
end


# user_controller.ex
defmodule UserController do
  @service Application.get_env(:app, :user_service)

  def create(params) do
    case @service.create_user(params) do
      {:ok, user} -> {:ok, user}
      {:error, reason} -> {:error, reason}
    end
  end
end


# test_helper.exs
ExUnit.start

# switch out our configured UserService with a Mimex double
Application.put_env(:app, :user_service, Mimex.stub(UserService))


# user_controller_test.exs
defmodule UserControllerTest do
  use ExUnit.Case

  import Mimex

  alias User
  alias UserService
  alias Mimex.UserService, as: FakeUserService

  setup do
    user = %User{id: 1}

    {:ok, user: user}
  end

  test "can create a user", {user: user} do
    # ensure our fake service returns the user we want when called
    expects FakeUserService, :create_user, fn (_params) -> {:ok, user} end

    {:ok, returned_user} = UserController.create(params)

    assert returned_user.id == user.id
  end

  test "can handle errors on user creation", {user: user} do
    # ensure that our fake service returns back an error
    expects FakeUserService, :create_user, fn (_params) -> {:error, "oh no it failed"} end

    {:error, reason} = UserController.create(params)

    assert reason == "oh no it failed"
  end
end
```
