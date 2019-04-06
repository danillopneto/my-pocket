import { PlacesService } from './../services/places.service';
import { Component, OnInit, Inject } from '@angular/core';
import { Observable } from 'rxjs';
import { Expense } from './../models/expense.model';
import { FormBuilder, FormGroup, Validators, FormControl } from '@angular/forms';
import { UtilityService } from '../services/utility.service';
import { Category } from '../models/category.model';
import { CategoriesService } from '../services/categories.service';
import { ExpensesService } from '../services/expense.service';
import { PaymentMethod } from '../models/payment-method.model';
import { PaymentMethodsService } from './../services/payment-methods.service';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material';
import { startWith, map } from 'rxjs/operators';
import { Place } from '../models/place.model';

@Component({
  selector: 'app-expense',
  templateUrl: './expense.component.html',
  styleUrls: ['./expense.component.scss']
})
export class ExpenseComponent implements OnInit {

  form: FormGroup;
  submitted: boolean = false;
  success: boolean = false;
  categories: Observable<Category[]>;
  paymentMethods: Observable<PaymentMethod[]>;
  options: string[] = [];
  filteredOptions: Observable<string[]>;

  constructor(
    private formBuilder: FormBuilder,
    private util: UtilityService,
    private expensesService: ExpensesService,
    private categoriesService: CategoriesService,
    private placesService: PlacesService,
    private paymentMethodsService: PaymentMethodsService,
    public dialogRef: MatDialogRef<ExpenseComponent>,
    @Inject(MAT_DIALOG_DATA) public data: string) {
    this.form = this.createFormGroup();

    if (data != null && data != '') {
      this.expensesService.get(data).subscribe(expense => {
        this.form = this.createFormGroup(expense);
      });
    }
  }

  ngOnInit() {
    this.categories = this.categoriesService.getAllFromUser();
    this.paymentMethods = this.paymentMethodsService.getAllFromUser();
    this.placesService.getAllFromUser().subscribe(data => {
        data.forEach(value => {
            this.options.push(value.description);
        });

        this.options = this.options.sort();
        this.filteredOptions = this.form.controls.place.valueChanges
        .pipe(
          startWith(''),
          map(value => this._filter(value))
        );
    });
  }

  ngAfterViewInit() {
  }

  createFormGroup(expense?: Expense) {
    var builder = this.formBuilder.group({
      idCategory: new FormControl('', [Validators.required]),
      dateJson: new FormControl(),
      description: new FormControl(),
      place: new FormControl(),
      id: new FormControl(),
      idPaymentMethod: new FormControl(),
      value: new FormControl()
    });

    if (expense != null) {
      var data: any = expense;
      data.dateJson = this.util.getDateFormat(expense.date);
      builder.patchValue(data);
    }

    return builder;
  }

  onCancelClick() {
    this.dialogRef.close();
  }

  onSubmit() {
    this.submitted = true;

    if (this.form.invalid) {
      return;
    }

    this.saveExpense();
    this.success = true;
  }

  saveExpense() {
    this.util.showLoading();

    debugger;
    if (this.form.value.place != null
          && this.form.value.place != '') {
      this.placesService.getCollectionReference(x => x.where('description', '==', this.form.value.place))
        .valueChanges().subscribe(data => {
          if (data.length == 0) {
            var newPlace = new Place();
            newPlace.description = this.form.value.place;
            this.placesService.save(newPlace)
              .catch(() => {
                this.util.hideLoading();
              });
          } else {
            this.saveExpenseData();
          }
        });
    } else {
      this.saveExpenseData();
    }
  }

  private saveExpenseData() {
    var idCategory = this.form.value.idCategory;
    var idPaymentMethod = this.form.value.idPaymentMethod;

    var data = this.util.getFullDate(this.form.value.dateJson.toJSON())
    var newExpense = new Expense(
      this.form.value.id,
      data,
      parseInt(this.util.getDayFromDate(data), 10),
      parseInt(this.util.getMonthFromDate(data), 10),
      parseInt(this.util.getYearFromDate(data), 10),
      idCategory,
      this.form.value.description,
      this.form.value.value,
      idPaymentMethod,
      this.form.value.place);

    this.expensesService
      .save(newExpense)
      .catch(() => {
        this.util.hideLoading();
      })
      .then(() => {
        this.onCancelClick();
        this.util.hideLoading();   
      })
      .finally(() => {
        this.util.hideLoading();
      });;
  }

  private _filter(value: string): string[] {
    const filterValue = value.toLowerCase();

    return this.options.filter(option => option.toLowerCase().includes(filterValue));
  }
}
