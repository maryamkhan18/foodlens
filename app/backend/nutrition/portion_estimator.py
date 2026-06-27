def estimate_portion(food_item):

    # SIMPLE REALISTIC ESTIMATION MODEL (MVP AI)

    if food_item == "chicken_leg":
        return 120  # grams

    if food_item == "rice":
        return 180

    if food_item == "kebab":
        return 90

    if food_item == "cucumber":
        return 50

    if food_item == "onion":
        return 30

    if food_item == "juice":
        return 250

    return 100