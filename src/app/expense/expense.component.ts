import { Component, OnInit } from '@angular/core';
import { Observable } from 'rxjs';
import { Expense } from './../models/expense.model';
import { FormBuilder, FormGroup, Validators, FormControl } from '@angular/forms';
import { UtilityService } from '../services/utility.service';
import { Category } from '../models/category.model';
import { CategoriesService } from '../services/categories.service';
import { ExpensesService } from '../services/expense.service';
import { PaymentMethod } from '../models/payment-method.model';
import { PaymentMethodsService } from './../services/payment-methods.service';

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

  constructor(
    private formBuilder: FormBuilder,
    private util: UtilityService,
    private expensesService: ExpensesService,
    private categoriesService: CategoriesService,
    private paymentMethodsService: PaymentMethodsService) {
    this.form = this.createFormGroup();
  }

  ngOnInit() {
  }

  ngAfterViewInit() {
    this.categories = this.categoriesService.getAll('description');
    this.paymentMethods = this.paymentMethodsService.getAll('description');
  }

  createFormGroup() {
    return this.formBuilder.group({
      idCategory: new FormControl('', [Validators.required]),
      date: new FormControl(),
      description: new FormControl(),
      id: new FormControl(),
      idPaymentMethod: new FormControl(),
      value: new FormControl()
    });
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

    var idCategory = this.form.value.idCategory;
    var idPaymentMethod = this.form.value.idPaymentMethod;

    var newExpense = new Expense(
      this.form.value.id,
      this.util.getDayFromDate(this.form.value.date.toJSON()),
      this.util.getMonthFromDate(this.form.value.date.toJSON()),
      this.util.getYearFromDate(this.form.value.date.toJSON()),
      idCategory,
      this.form.value.description,
      this.form.value.value,
      idPaymentMethod);

    newExpense.category = this.categoriesService.getCollectionReference().doc(idCategory).ref;
    newExpense.paymentMethod = this.paymentMethodsService.getCollectionReference().doc(idPaymentMethod).ref;

    this.expensesService
      .save(newExpense)
      .catch(() => {
        this.util.hideLoading();
      })
      .then(() => {
        this.form = this.createFormGroup();
      })
      .finally(() => {
        this.util.hideLoading();
      });;
  }
}
